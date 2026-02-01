#!/usr/bin/env python3
"""
Script pour séparer un fichier FASTA multi-espèces en fichiers individuels
"""
from Bio import SeqIO
import sys
import os

def split_fasta(input_file, output_dir):
    """
    Sépare un fichier FASTA en plusieurs fichiers, un par séquence
    
    Args:
        input_file: chemin du fichier FASTA d'entrée
        output_dir: répertoire de sortie
    """
    # Créer le répertoire de sortie s'il n'existe pas
    os.makedirs(output_dir, exist_ok=True)
    
    # Compteur de séquences
    count = 0
    
    # Lire et séparer les séquences
    for record in SeqIO.parse(input_file, "fasta"):
        # Nettoyer le nom (enlever caractères spéciaux)
        species_name = record.id.replace("/", "_").replace(" ", "_")
        
        # Créer le nom du fichier de sortie
        output_file = os.path.join(output_dir, f"{species_name}.fasta")
        
        # Écrire la séquence dans son propre fichier
        with open(output_file, "w") as f:
            SeqIO.write(record, f, "fasta")
        
        count += 1
        print(f"✓ Séquence extraite: {species_name}")
    
    print(f"\n✅ Total: {count} séquences séparées dans {output_dir}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python split_fasta.py <input.fasta> <output_directory>")
        sys.exit(1)
    
    input_fasta = sys.argv[1]
    output_directory = sys.argv[2]
    
    split_fasta(input_fasta, output_directory)
