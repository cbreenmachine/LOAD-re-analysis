# ==========================================
# GEMBS WORKFLOW RULES
# ==========================================

# Initialize gemBS project
rule gembs_init:
    input:
        ref = REFERENCE
    output:
        conf = f"{GEMBS_DIR}/gembs.conf",
        csv = f"{GEMBS_DIR}/metadata.csv"
    conda:
        "gemBS"
    shell:
        """
        mkdir -p {GEMBS_DIR}
        cd {GEMBS_DIR}
        
        # Initialize gemBS project
        gemBS init
        
        # Create metadata CSV file
        echo "sample_name,file1,file2,sample_type,sample_group" > metadata.csv
        """

# Create gemBS metadata file
rule create_gembs_metadata:
    input:
        reads_r1 = expand(f"{EXTRACTED_READS_DIR}/{{sample}}_R1.fastq.gz", sample=SAMPLES),
        reads_r2 = expand(f"{EXTRACTED_READS_DIR}/{{sample}}_R2.fastq.gz", sample=SAMPLES),
        conf = f"{GEMBS_DIR}/gembs.conf"
    output:
        csv = f"{GEMBS_DIR}/metadata_complete.csv"
    run:
        import os
        with open(output.csv, 'w') as f:
            f.write("sample_name,file1,file2,sample_type,sample_group\n")
            for sample in SAMPLES:
                r1_path = os.path.abspath(f"{EXTRACTED_READS_DIR}/{sample}_R1.fastq.gz")
                r2_path = os.path.abspath(f"{EXTRACTED_READS_DIR}/{sample}_R2.fastq.gz")
                f.write(f"{sample},{r1_path},{r2_path},BS,group1\n")

# Prepare reference for gemBS
rule gembs_prepare_reference:
    input:
        ref = REFERENCE,
        csv = f"{GEMBS_DIR}/metadata_complete.csv"
    output:
        index = f"{GEMBS_DIR}/reference/reference.fa.bsb"
    conda:
        "gemBS"
    threads: 8
    shell:
        """
        cd {GEMBS_DIR}
        
        # Copy reference to gemBS directory
        mkdir -p reference
        cp ../{input.ref} reference/
        
        # Configure gemBS to use our reference and metadata
        gemBS config reference reference/{REFERENCE}
        gemBS config metadata {input.csv}
        gemBS config threads {threads}
        
        # Prepare reference
        gemBS prepare-reference
        """

# Run gemBS mapping
rule gembs_mapping:
    input:
        csv = f"{GEMBS_DIR}/metadata_complete.csv",
        index = f"{GEMBS_DIR}/reference/reference.fa.bsb"
    output:
        bams = expand(f"{GEMBS_DIR}/{{sample}}_gembs.bam", sample=SAMPLES),
        report = f"{GEMBS_DIR}/gembs_mapping_report.json"
    conda:
        "gemBS"
    threads: 8
    shell:
        """
        cd {GEMBS_DIR}
        
        # Run mapping
        gemBS map
        
        # Create mapping report
        gemBS mapping-report > gembs_mapping_report.json
        
        # Copy and rename BAM files to expected locations
        for sample in {' '.join(SAMPLES)}; do
            if [ -f mapping/${{sample}}.bam ]; then
                cp mapping/${{sample}}.bam ${{sample}}_gembs.bam
            fi
        done
        """