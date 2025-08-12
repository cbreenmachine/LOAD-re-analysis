
# ==========================================
# UTILITY RULES
# ==========================================

# Clean intermediate files
rule clean:
    shell:
        """
        rm -rf {EXTRACTED_READS_DIR}
        rm -rf bismark_genome
        rm -rf {BISMARK_DIR}/temp
        """

# Create summary report
rule summary:
    input:
        bismark_reports = expand(f"{BISMARK_DIR}/{{sample}}_bismark_report.txt", sample=SAMPLES),
        gembs_report = f"{GEMBS_DIR}/gembs_mapping_report.json"
    output:
        summary = "alignment_summary.txt"
    shell:
        """
        echo "Alignment Summary Report" > {output.summary}
        echo "======================" >> {output.summary}
        echo "" >> {output.summary}
        
        echo "Bismark Results:" >> {output.summary}
        echo "---------------" >> {output.summary}
        for report in {input.bismark_reports}; do
            echo "File: $report" >> {output.summary}
            grep -E "(Mapping efficiency|Total number of sequences)" $report >> {output.summary}
            echo "" >> {output.summary}
        done
        
        echo "gemBS Results:" >> {output.summary}
        echo "-------------" >> {output.summary}
        if [ -f {input.gembs_report} ]; then
            echo "gemBS mapping report available at: {input.gembs_report}" >> {output.summary}
        fi
        
        echo "" >> {output.summary}
        echo "Output files:" >> {output.summary}
        echo "Bismark BAMs: {BISMARK_DIR}/*_bismark.bam" >> {output.summary}
        echo "gemBS BAMs: {GEMBS_DIR}/*_gembs.bam" >> {output.summary}
        """