# ==========================================
# BISMARK WORKFLOW RULES
# ==========================================

# Prepare reference genome for Bismark
rule bismark_genome_preparation:
    input:
        ref = f"{BISMARK_DIR}/genome/reference.fa"
    output:
        # Bismark creates this subdirectory structure within bismark_results
        ct_conv = f"{BISMARK_DIR}/genome/Bisulfite_Genome/CT_conversion/genome_mfa.CT_conversion.fa",
        ga_conv = f"{BISMARK_DIR}/genome/Bisulfite_Genome/GA_conversion/genome_mfa.GA_conversion.fa",
    conda: "../envs/bismark.yml"
    threads: 8
    params: 
        genome_dir = f"{BISMARK_DIR}/genome",
        ref_basename = lambda wildcards, input: os.path.basename(input.ref)
    shell:
        """
        # Prepare genome (this will create the Bisulfite_Genome subdirectory)
        bismark_genome_preparation --parallel {threads} {params.genome_dir}
        """

# Run Bismark alignment
rule bismark_alignment:
    input:
        ct_conv = f"{BISMARK_DIR}/genome/Bisulfite_Genome/CT_conversion/genome_mfa.CT_conversion.fa",
        ga_conv = f"{BISMARK_DIR}/genome/Bisulfite_Genome/GA_conversion/genome_mfa.GA_conversion.fa",
        ref = f"{BISMARK_DIR}/genome/reference.fa",
        r1 = f"{EXTRACTED_READS_DIR}/{{sample}}_R1.fastq.gz",
        r2 = f"{EXTRACTED_READS_DIR}/{{sample}}_R2.fastq.gz"
    output:
        bam = f"{BISMARK_DIR}/alignments/{{sample}}_bismark.bam",
        report = f"{BISMARK_DIR}/reports/{{sample}}_bismark_report.txt"
    params:
        genome_dir = f"{BISMARK_DIR}/genome",  # Directory containing Bisulfite_Genome folder
        output_dir = f"{BISMARK_DIR}/alignments",
        temp_dir = f"{BISMARK_DIR}/temp",
        reports_dir = f"{BISMARK_DIR}/reports"
    conda: "../envs/bismark.yml"
    threads: 8
    shell:
        """
        # Run Bismark alignment
        bismark --parallel {threads} \
                --genome {params.genome_dir} \
                --output_dir {params.output_dir} \
                --temp_dir {params.temp_dir} \
                --basename {wildcards.sample}_bismark \
                -1 {input.r1} \
                -2 {input.r2}
        
        """