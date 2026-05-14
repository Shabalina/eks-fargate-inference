import streamlit as st
import requests
from PIL import Image
import io
import os
import boto3
import json
import textwrap
from pathlib import PurePosixPath

# Settings
API_URL = st.secrets["API_URL"]
BUCKET = st.secrets["BUCKET_NAME"]
PREFIX = "converted_recurtion_data/dino_demo_sample"
ITEMS_PER_PAGE = 10

def get_sorted_s3_keys(s3_keys, manifest_order):
    # Map filename -> full S3 key for quick lookup
    key_map = {PurePosixPath(k).name: k for k in s3_keys}
    
    sorted_keys = []
    
    # add keys based on the JSON order
    for filename in manifest_order:
        if filename in key_map:
            sorted_keys.append(key_map[filename])
            # Remove from map so we don't duplicate later
            del key_map[filename]
            
    # add any leftover S3 images alphabetically
    remaining_keys = sorted(list(key_map.values()))
    
    return sorted_keys + remaining_keys

def get_s3_images():
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX)
    return [obj['Key'] for obj in response.get('Contents', []) if obj['Key'].lower().endswith(('.png', '.jpg', '.jpeg'))]

# Load Manifest
@st.cache_data # Cache to not reload every click
def load_manifest():
    manifest_path = os.path.join(os.path.dirname(__file__), "metadata.json")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r") as f:
            return json.load(f)
    return {}

manifest = load_manifest()
curated_filenames = list(manifest.keys())
selected_image_bytes = None

# S3 Client
s3 = boto3.client(
    "s3",
    aws_access_key_id=st.secrets["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=st.secrets["AWS_SECRET_ACCESS_KEY"],
    region_name=st.secrets["AWS_REGION"]
)

if 'page_number' not in st.session_state:
    st.session_state['page_number'] = 0

st.set_page_config(page_title="Cell DINOv2 Classifier", page_icon="🔬", layout="centered")

# Page title and description
st.title("🔬 Cell siRNA Classifier")
with st.expander("📖 About this Project & Drug Discovery Impact", expanded=False):
    st.markdown("""
    This application runs a finetuned DINOv2 model to classify cellular microscopy images based on the specific chemical treatment (siRNA) applied during laboratory testing.
    
    🧬 **Why is this needed?**
    Manual analysis of millions of cellular images is impossible for human scientists. Automating this classification allows pharmaceutical companies to rapidly screen thousands of drug candidates, accelerating drug discovery timelines and reducing lab-to-clinic costs.
    """)
st.divider()

# --- THE TOP SLOT FOR RESULTS---
# Container stays empty until a prediction is made.
results_container = st.container()

st.markdown("""
Select a file from the gallery below to run a prediction using the 
**DINOv2-based inference engine**. The system will automatically identify the corresponding **siRNA ID**.
""")

# --- s3 GALLERY LOGIC---
with st.container():
    st.subheader("S3 Test Sample Gallery")
    raw_keys = get_s3_images()
    image_keys = get_sorted_s3_keys(raw_keys, curated_filenames)

    if image_keys:
        # Calculate total pages
        n_images = len(image_keys)
        n_pages = (n_images // ITEMS_PER_PAGE) + (1 if n_images % ITEMS_PER_PAGE > 0 else 0)

        # Slice the list for the current page
        start_idx = st.session_state['page_number'] * ITEMS_PER_PAGE
        end_idx = start_idx + ITEMS_PER_PAGE
        current_batch = image_keys[start_idx:end_idx]

        # --- RENDER GALLERY ---
        cols = st.columns(5)
        for idx, key in enumerate(current_batch):
            # Generate a temporary URL that lasts for 1 hour
            url = s3.generate_presigned_url('get_object',
                                            Params={'Bucket': BUCKET, 'Key': key},
                                            ExpiresIn=3600)
            
            with cols[idx % 5]:
                st.image(url, use_container_width=True)
                s3_filename = PurePosixPath(key).name
                # Display the filename as a caption (truncating if too long)
                display_name = (s3_filename[:18] + '..') if len(s3_filename) > 20 else s3_filename
                st.caption(f"📄 {display_name}")

                if st.button("🔎 Analyze This Sample", key=f"btn_{s3_filename}", use_container_width=True, type="primary"):
                    # Get the raw bytes from S3
                    image_obj = s3.get_object(Bucket=BUCKET, Key=key)
                    selected_image_bytes = image_obj['Body'].read()

                    current_filename = s3_filename # Store filename for manifest lookup

                    # Convert bytes to a PIL Image object and store image in session state
                    st.session_state['preview_img'] = Image.open(io.BytesIO(selected_image_bytes))


    # --- PAGINATION CONTROLS ---
    st.write(f"Showing page {st.session_state['page_number'] + 1} of {n_pages}")

    st.markdown("""
    <style>
    /* ==========================================
       1. GLOBAL / PAGINATION BUTTONS (3:1 Ratio)
       ========================================== */
    div[data-testid="stColumn"] .stButton {
        display: flex !important;
        justify-content: center !important;
        width: 100% !important; /* Force wrapper to use full column width */
    }
    div[data-testid="stColumn"] button p {
        line-height: 1.5 !important;
    }
    div[data-testid="stColumn"] button {
        height: 65px !important;  /* Strict height force */
        width: 195px !important;
        min-width: 195px !important;    /* FORCE browser to not compress width */
        flex-shrink: 0 !important;      /* Prevent flexbox shrinking bugs */
            
        display: flex !important;
        flex-direction: column !important;
        align-items: center !important;
        justify-content: center !important;
    }
    </style>
    """, unsafe_allow_html=True)
    
    col_prev, col_spacer, col_next = st.columns([1, 4, 1])

    with col_prev:
        if st.button("◀️\nPrevious", key="btn_prev_page") and st.session_state['page_number'] > 0:
            st.session_state['page_number'] -= 1
            st.rerun()

    with col_next:
        if st.button("▶️\nNext", key="btn_next_page") and st.session_state['page_number'] < n_pages - 1:
            st.session_state['page_number'] += 1
            st.rerun()


# --- PREDICTION LOGIC (Rendering to the TOP) ---
if selected_image_bytes is not None:
    with results_container:
        st.success("Analysis Target Selected")
        col_img, col_res = st.columns([1, 1]) 

        with col_img:
                st.image(st.session_state['preview_img'], use_container_width=True)

        with col_res:
            with st.spinner("🔬 Talking to SageMaker... (First analysis may take few seconds while the model warms up)"):
                try:
                    # Send the binary data
                    headers = {"Content-Type": "image/jpeg"}
                    response = requests.post(API_URL, data=selected_image_bytes, headers=headers, timeout=30)
                    
                    if response.status_code == 200:
                        result = response.json()

                        predicted_id = str(result.get('prediction') or result.get('sirna_id'))
                        confidence = result.get('confidence', 0)

                        # --- GROUND TRUTH LOGIC ---
                        ground_truth = manifest.get(current_filename, {}).get("label")
                        if ground_truth:
                            is_match = str(predicted_id) == str(ground_truth)
                            if is_match:
                                st.success(f"🎯 **Correct Prediction!** The model accurately identified siRNA ID: **{predicted_id}**.")
                            else:
                                st.error(f"⚠️ **Prediction Variance.** The model predicted **{predicted_id}**, but the labeled Ground Truth is **{ground_truth}**.")
                                                
                        # Layout for results
                        col1, col2 = st.columns(2)
                        with col1:
                            st.metric("Predicted siRNA ID", f"#{result.get('sirna_id')}")
                            if ground_truth:
                                # small margin-top fix to align with the metric height
                                st.markdown(f"<div style='margin-top: -15px;'><b>Actual ID:</b> <code>#{ground_truth}</code></div>", unsafe_allow_html=True)
                        with col2:
                            confidence = result.get('confidence', 0)
                            st.metric("Confidence Score", f"{confidence:.2%}")
                            st.progress(confidence)
                        
                    else:
                        st.error(f"API Error ({response.status_code}): {response.text}")
                        
                except Exception as e:
                    st.exception(f"Connection Error: {e}")

st.divider()
st.caption("Built with Streamlit • Powered by AWS SageMaker & DINOv2")