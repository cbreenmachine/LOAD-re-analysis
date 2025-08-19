# ==========================================
# UTILITY RULES
# ==========================================

# Clean intermediate files
rule clean:
    shell:
        """
        rm -rf {EXTRACTED_READS_DIR}
        rm -rf {BISMARK_DIR}/temp
        rm -rf {GEMBS_DIR}/temp
        """

# Clean all output files (complete reset)
rule clean_all:
    shell:
        """
        rm -rf {EXTRACTED_READS_DIR}
        rm -rf {BISMARK_DIR}
        rm -rf {GEMBS_DIR}
        """

# Create summary report
rule summary:
    input:
        bismark_reports = expand(f"{BISMARK_DIR}/reports/{{sample}}_bismark_report.txt", sample=SAMPLES),
        # gembs_report = f"{GEMBS_DIR}/gembs_mapping_report.json"
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
            if [ -f "$report" ]; then
                grep -E "(Mapping efficiency|Total number of sequences)" "$report" >> {output.summary} || echo "No mapping stats found" >> {output.summary}
            else
                echo "Report file not found: $report" >> {output.summary}
            fi
            echo "" >> {output.summary}
        done
        
        echo "gemBS Results:" >> {output.summary}
        echo "-------------" >> {output.summary}
        echo "gemBS analysis currently disabled" >> {output.summary}
        
        echo "" >> {output.summary}
        echo "Output files:" >> {output.summary}
        echo "Bismark BAMs: {BISMARK_DIR}/alignments/*_bismark.bam" >> {output.summary}
        echo "Bismark Reports: {BISMARK_DIR}/reports/*_bismark_report.txt" >> {output.summary}
        echo "Bismark Genome: {BISMARK_DIR}/genome/" >> {output.summary}
        echo "gemBS BAMs: {GEMBS_DIR}/*_gembs.bam" >> {output.summary}
        """