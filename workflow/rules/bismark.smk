# ==========================================
# BISMARK WORKFLOW RULES
# ==========================================

# Prepare reference genome for Bismark
rule bismark_genome_preparation:
    input:
        ref = REFERENCE
    output:
        # Bismark creates this subdirectory structure
        ct_conv = f"{BISMARK_DIR}/Bisulfite_Genome/CT_conversion/genome_mfa.CT_conversion.fa",
        ga_conv = f"{BISMARK_DIR}/Bisulfite_Genome/GA_conversion/genome_mfa.GA_conversion.fa"
    conda: "../envs/bismark.yml"
    threads: 8
    params: 
        bismark_dir = BISMARK_DIR,
        ref_basename = lambda wildcards, input: os.path.basename(input.ref)
    shell:
        """
        mkdir -p {params.bismark_dir}
        
        # Copy reference to bismark directory with correct name
        cp {input.ref} {params.bismark_dir}/{params.ref_basename}
        
        # Prepare genome (this will create the Bisulfite_Genome subdirectory)
        bismark_genome_preparation --parallel {threads} {params.bismark_dir}
        """

# Run Bismark alignment
rule bismark_alignment:
    input:
        ct_conv = f"{BISMARK_DIR}/Bisulfite_Genome/CT_conversion/genome_mfa.CT_conversion.fa",
        ga_conv = f"{BISMARK_DIR}/Bisulfite_Genome/GA_conversion/genome_mfa.GA_conversion.fa",
        r1 = f"{EXTRACTED_READS_DIR}/{{sample}}_R1.fastq.gz",
        r2 = f"{EXTRACTED_READS_DIR}/{{sample}}_R2.fastq.gz"
    output:
        bam = f"{BISMARK_DIR}/{{sample}}_bismark.bam",
        report = f"{BISMARK_DIR}/{{sample}}_bismark_report.txt"
    params:
        genome_dir = BISMARK_DIR,  # Directory containing Bisulfite_Genome folder
        output_dir = BISMARK_DIR,
        temp_dir = f"{BISMARK_DIR}/temp"
    conda: "../envs/bismark.yml"
    threads: 8
    shell:
        """
        # Create temp directory
        mkdir -p {params.temp_dir}
        
        # Run Bismark alignment
        bismark --parallel {threads} \
                --genome {params.genome_dir} \
                --output_dir {params.output_dir} \
                --temp_dir {params.temp_dir} \
                --basename {wildcards.sample}_bismark \
                -1 {input.r1} \
                -2 {input.r2}
        
        # Bismark creates files with _pe suffix for paired-end reads
        # Move and rename output files to match expected names
        if [ -f "{params.output_dir}/{wildcards.sample}_bismark_pe.bam" ]; then
            mv "{params.output_dir}/{wildcards.sample}_bismark_pe.bam" {output.bam}
        elif [ -f "{params.output_dir}/{wildcards.sample}_bismark.bam" ]; then
            mv "{params.output_dir}/{wildcards.sample}_bismark.bam" {output.bam}
        fi
        
        if [ -f "{params.output_dir}/{wildcards.sample}_bismark_PE_report.txt" ]; then
            mv "{params.output_dir}/{wildcards.sample}_bismark_PE_report.txt" {output.report}
        elif [ -f "{params.output_dir}/{wildcards.sample}_bismark_report.txt" ]; then
            mv "{params.output_dir}/{wildcards.sample}_bismark_report.txt" {output.report}
        fi
        
        # Clean up temporary directory
        rm -rf {params.temp_dir}
        """