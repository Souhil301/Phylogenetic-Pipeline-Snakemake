
import os

# Configuration
RAW_FASTA = "data/raw/seqs-RNA.fasta"

# =============================================================================
# RÈGLE FINALE : Ce qu'on veut produire
# =============================================================================

rule all:
    input:
        # L'arbre phylogénétique principal
        "results/trees/phylogenetic_tree.treefile",
        # Le résumé des résultats
        "results/summary/analysis_summary.txt",
        # Le diagramme du workflow
        "dag/workflow.png"

# =============================================================================
# ÉTAPE 1 : CONTRÔLE QUALITÉ DES DONNÉES
# =============================================================================

rule quality_control:
    """
    Analyse la qualité du fichier FASTA d'entrée
    """
    input:
        fasta = RAW_FASTA
    output:
        qc_report = "results/qc/quality_report.txt"
    log:
        "logs/01_quality_control.log"
    shell:
        """
        echo "[$(date)] === CONTRÔLE QUALITÉ ===" > {log}
        mkdir -p results/qc
        
        # Créer le rapport QC
        echo "RAPPORT DE CONTRÔLE QUALITÉ" > {output.qc_report}
        echo "===========================" >> {output.qc_report}
        echo "" >> {output.qc_report}
        echo "Fichier d'entrée: {input.fasta}" >> {output.qc_report}
        echo "Date d'analyse: $(date)" >> {output.qc_report}
        echo "" >> {output.qc_report}
        
        # Nombre de séquences
        NUM_SEQ=$(grep -c '^>' {input.fasta})
        echo "Nombre de séquences: $NUM_SEQ" >> {output.qc_report}
        
        # Longueur totale
        TOTAL_LEN=$(grep -v '^>' {input.fasta} | tr -d '\\n' | wc -c)
        echo "Longueur totale: $TOTAL_LEN bp" >> {output.qc_report}
        
        # Longueur moyenne
        AVG_LEN=$((TOTAL_LEN / NUM_SEQ))
        echo "Longueur moyenne: $AVG_LEN bp" >> {output.qc_report}
        
        echo "" >> {output.qc_report}
        echo "Liste des 10 premières séquences:" >> {output.qc_report}
        grep '^>' {input.fasta} | head -10 >> {output.qc_report}
        
        # Copier dans le log
        cat {output.qc_report} >> {log}
        echo "[$(date)] ✓ Contrôle qualité terminé" >> {log}
        """

# =============================================================================
# ÉTAPE 2 : ALIGNEMENT MULTIPLE AVEC MAFFT
# =============================================================================

rule multiple_sequence_alignment:
    """
    Aligne toutes les séquences ensemble avec MAFFT
    C'est l'étape la plus importante pour la phylogénie
    """
    input:
        fasta = RAW_FASTA,
        qc = "results/qc/quality_report.txt"
    output:
        aligned = "results/alignment/sequences_aligned.fasta"
    log:
        "logs/02_alignment.log"
    threads: 4
    shell:
        """
        echo "[$(date)] === ALIGNEMENT MULTIPLE ===" > {log}
        mkdir -p results/alignment
        
        echo "Début de l'alignement MAFFT..." >> {log}
        echo "Nombre de threads: {threads}" >> {log}
        echo "Fichier d'entrée: {input.fasta}" >> {log}
        
        # Lancer MAFFT
        mafft --auto --thread {threads} {input.fasta} > {output.aligned} 2>> {log}
        
        # Vérifications
        NUM_ALIGNED=$(grep -c '^>' {output.aligned})
        echo "Nombre de séquences alignées: $NUM_ALIGNED" >> {log}
        echo "[$(date)] ✓ Alignement terminé" >> {log}
        """

# =============================================================================
# ÉTAPE 3 : CONSTRUCTION DE L'ARBRE PHYLOGÉNÉTIQUE AVEC IQ-TREE
# =============================================================================

rule phylogenetic_tree_construction:
    """
    Construit l'arbre phylogénétique avec IQ-TREE
    - Sélection automatique du meilleur modèle évolutif (-m MFP)
    - Bootstrap ultrafast avec 1000 réplicats (-bb 1000)
    """
    input:
        aligned = "results/alignment/sequences_aligned.fasta"
    output:
        tree = "results/trees/phylogenetic_tree.treefile",
        iqtree_report = "results/trees/phylogenetic_tree.iqtree",
        model_info = "results/trees/phylogenetic_tree.log"
    params:
        prefix = "results/trees/phylogenetic_tree"
    log:
        "logs/03_tree_construction.log"
    threads: 4
    shell:
        """
        echo "[$(date)] === CONSTRUCTION DE L'ARBRE PHYLOGÉNÉTIQUE ===" > {log}
        mkdir -p results/trees
        
        echo "Alignement d'entrée: {input.aligned}" >> {log}
        echo "Nombre de threads: {threads}" >> {log}
        echo "Préfixe de sortie: {params.prefix}" >> {log}
        echo "" >> {log}
        echo "Début de l'analyse IQ-TREE..." >> {log}
        
        # Lancer IQ-TREE
        iqtree -s {input.aligned} \\
               -pre {params.prefix} \\
               -nt {threads} \\
               -m MFP \\
               -bb 1000 >> {log} 2>&1
        
        echo "" >> {log}
        echo "[$(date)] ✓ Arbre phylogénétique construit" >> {log}
        echo "Fichier de l'arbre: {output.tree}" >> {log}
        echo "Rapport détaillé: {output.iqtree_report}" >> {log}
        """

# =============================================================================
# ÉTAPE 4 : CRÉATION DU RÉSUMÉ FINAL
# =============================================================================

rule create_summary:
    """
    Crée un résumé complet de l'analyse
    """
    input:
        qc = "results/qc/quality_report.txt",
        tree = "results/trees/phylogenetic_tree.treefile",
        iqtree = "results/trees/phylogenetic_tree.iqtree"
    output:
        summary = "results/summary/analysis_summary.txt"
    log:
        "logs/04_summary.log"
    shell:
        """
        echo "[$(date)] === CRÉATION DU RÉSUMÉ ===" > {log}
        mkdir -p results/summary
        
        # Créer le résumé
        echo "========================================" > {output.summary}
        echo "   ANALYSE PHYLOGÉNÉTIQUE - RÉSUMÉ" >> {output.summary}
        echo "========================================" >> {output.summary}
        echo "" >> {output.summary}
        echo "Date d'analyse: $(date)" >> {output.summary}
        echo "" >> {output.summary}
        
        # Inclure le rapport QC
        echo "--- DONNÉES D'ENTRÉE ---" >> {output.summary}
        cat {input.qc} >> {output.summary}
        echo "" >> {output.summary}
        
        # Informations sur l'arbre
        echo "--- ARBRE PHYLOGÉNÉTIQUE ---" >> {output.summary}
        echo "Fichier: {input.tree}" >> {output.summary}
        echo "Nombre de branches: $(grep -o '(' {input.tree} | wc -l)" >> {output.summary}
        echo "" >> {output.summary}
        
        # Instructions de visualisation
        echo "--- VISUALISATION ---" >> {output.summary}
        echo "Option 1 - FigTree (local):" >> {output.summary}
        echo "  figtree {input.tree}" >> {output.summary}
        echo "" >> {output.summary}
        echo "Option 2 - iTOL (en ligne):" >> {output.summary}
        echo "  1. Aller sur https://itol.embl.de/" >> {output.summary}
        echo "  2. Cliquer sur 'Upload'" >> {output.summary}
        echo "  3. Sélectionner le fichier {input.tree}" >> {output.summary}
        echo "" >> {output.summary}
        
        # Rapport détaillé
        echo "--- RAPPORT DÉTAILLÉ ---" >> {output.summary}
        echo "Voir le fichier: {input.iqtree}" >> {output.summary}
        echo "" >> {output.summary}
        
        echo "=======================================" >> {output.summary}
        
        cat {output.summary} >> {log}
        echo "[$(date)] ✓ Résumé créé" >> {log}
        """

# =============================================================================
# GÉNÉRATION DU DIAGRAMME DAG
# =============================================================================

rule generate_dag:
    """
    Génère le diagramme de flux du workflow
    """
    output:
        png = "dag/workflow.png",
        pdf = "dag/workflow.pdf"
    shell:
        """
        mkdir -p dag
        
        # PNG
        snakemake --dag | dot -Tpng > {output.png} 2>/dev/null || \\
            echo "Note: Impossible de générer le DAG (normal pendant l'exécution)"
        
        # PDF
        snakemake --dag | dot -Tpdf > {output.pdf} 2>/dev/null || \\
            echo "Note: Impossible de générer le DAG (normal pendant l'exécution)"
        """
