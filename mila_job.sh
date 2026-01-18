#!/bin/bash
#SBATCH --job-name=SocialSimPIIRemoval
#SBATCH --time=10:00:00
#SBATCH --mem-per-cpu=100G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10

module load python/3.10

# Adjust this to your environment
source ~/ENV/bin/activate
cd ~/SM-based-personas/bluesky_persona_pii/src

# Set directories
export INPUT_DATA="${SCRATCH}/processed-data"
export TEMP_DATA="${SCRATCH}/temp_pii"
export OUTPUT_DATA="${SCRATCH}/cleaned"

# Create directories
mkdir -p "$TEMP_DATA"
mkdir -p "$OUTPUT_DATA"
mkdir -p data_removal
touch data_removal/did_removal_list.txt

# Step 1: Merge all partitions
echo "Starting merge_df.py..."
python merge_df.py

# Step 2: PII Removal
echo "Starting pii_temp.py..."
python pii_temp.py

# Step 3: Rebuild chains
echo "Starting rebuild_chains.py..."
python rebuild_chains.py

# Step 4: Rebuild clusters with hashed user IDs
echo "Starting rebuild_clusters.py..."
if [ ! -f .env ]; then
    echo "Creating .env with HASH_SECRET..."
    echo HASH_SECRET=$(openssl rand -base64 32) > .env
fi
python rebuild_clusters.py

echo "Job completed successfully."

cd ../finetuning
sbatch mila_job.sh