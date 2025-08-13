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
    conda:
        "../envs/bismark"
    threads: 8
    shell:
        """
        mkdir -p bismark_genome
        cp {input.ref} bismark_genome/
        bismark_genome_preparation --parallel {threads} bismark_genome/
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
    conda:
        "../envs/bismark"
    threads: 8
    shell:
        """
        mkdir -p {BISMARK_DIR}
        
        # Run Bismark alignment
        bismark --parallel {threads} \
                --genome {input.genome} \
                --output_dir {BISMARK_DIR} \
                --temp_dir {BISMARK_DIR}/temp \
                --basename {wildcards.sample}_bismark \
                -1 {input.r1} \
                -2 {input.r2}
        
        # Move and rename output files
        mv {BISMARK_DIR}/{wildcards.sample}_bismark_pe.bam {output.bam}
        mv {BISMARK_DIR}/{wildcards.sample}_bismark_PE_report.txt {output.report}
        
        # Clean up temporary directory
        rm -rf {BISMARK_DIR}/temp
        """