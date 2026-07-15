# =============================================================================
# run_all.R - Script maître du pipeline BCEAO Inclusion Financière
# =============================================================================
# Auteurs : Anna A. JOYCE, Bocar M. DIACK, Wendvi A. D. MANDO, Oumar FAROUK,
#           Saran NDIAYE
#
# Exécute toutes les étapes du pipeline dans l'ordre :
#   1. Configuration et fonctions utilitaires
#   2. Génération des dictionnaires (optionnel - à faire une fois)
#   3. Chargement des données brutes
#   4. Construction de la table individus
#   5. Construction de la table ménages
#   6. Rapport QAQC
#   7. Rendu du rapport HTML (pipeline.Rmd)
#
# Le rapport Word (rapport_word.Rmd) ne fait pas partie du pipeline : il
# s'obtient séparément en ouvrant le Rmd et en cliquant sur Knit.
#
# Aucun chemin n'est à renseigner : la racine du projet est détectée
# automatiquement à partir de l'emplacement de ce fichier.
#
# Usage depuis RStudio :  ouvrir run_all.R puis cliquer sur Source
# Usage en ligne de commande :  Rscript run_all.R
# =============================================================================

rm(list = ls())
gc()

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(glue, writexl, rmarkdown)

# ── Racine du projet (détectée, aucun chemin en dur) ──────────────────────────
# Fonctionne via Rscript (--file), source() dans RStudio (ofile), le bouton
# Source de l'éditeur (rstudioapi), et à défaut le répertoire de travail.
racine_projet <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  if (length(f) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", f[1]), winslash = "/")))
  }
  for (i in rev(seq_len(sys.nframe()))) {
    of <- sys.frame(i)$ofile
    if (!is.null(of)) return(dirname(normalizePath(of, winslash = "/")))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getSourceEditorContext()$path,
                  error = function(e) "")
    if (nzchar(p)) return(dirname(normalizePath(p, winslash = "/")))
  }
  normalizePath(getwd(), winslash = "/")
}

BASE_DIR <- racine_projet() # Si la fonction ci-dessus échouent, mettre le chemin du fichier run_all.R ici
R_DIR    <- file.path(BASE_DIR, "R")
message("Racine du projet : ", BASE_DIR)

# ── Étape 0 : Charger configuration + fonctions utilitaires ──────────────────
message("══════════════════════════════════════════════════════════")
message("[0] Configuration et fonctions utilitaires")
message("══════════════════════════════════════════════════════════")
source(file.path(R_DIR, "00_config.R"),    encoding = "UTF-8")
source(file.path(R_DIR, "utils.R"),        encoding = "UTF-8")

# ── Étape 0b : Dictionnaires de variables ────────────────────────────────────
# 00c_fill_dict.R crée et pré-remplit les CSV dans data/aux_file/.
# Ils sont utilisés par apply_var_dictionary() dans build_individus/menages.
# À relancer si les fichiers .dta changent (nouveau round d'enquête).
message("\n══════════════════════════════════════════════════════════")
message("[0b] Dictionnaires de variables")
message("══════════════════════════════════════════════════════════")
dict_membres_path <- file.path(BASE_DIR, "data", "aux_file", "membres_dict.csv")
dict_menage_path  <- file.path(BASE_DIR, "data", "aux_file", "menage_dict.csv")

if (!file.exists(dict_membres_path) || !file.exists(dict_menage_path)) {
  message("  Dictionnaires absents - création à partir des fichiers .dta...")
  source(file.path(R_DIR, "00c_fill_dict.R"), encoding = "UTF-8")
  fill_all_dicts()
} else {
  message("  Dictionnaires déjà présents dans data/aux_file/")
  message("    (pour régénérer : supprimer les CSV et relancer)")
}

# ── Étape 1 : Chargement des données brutes ───────────────────────────────────
message("\n══════════════════════════════════════════════════════════")
message("[1] Chargement des données brutes (.dta)")
message("══════════════════════════════════════════════════════════")
source(file.path(R_DIR, "01_load_data.R"), encoding = "UTF-8")
raw <- load_all_data()

# ── Étape 2 : Construction table individus ────────────────────────────────────
message("\n══════════════════════════════════════════════════════════")
message("[2] Construction de la table individus")
message("══════════════════════════════════════════════════════════")
source(file.path(R_DIR, "02_individus.R"), encoding = "UTF-8")
individus <- build_individus(raw)

# Nettoyage paramétrique
message("\n── Nettoyage individus (run_cleaning_pipeline) ──")
individus <- run_cleaning_pipeline(individus, CLEANING_PARAMS_IND, label = "Individus")

# Imputation multiple mice sur variables démographiques
message("\n── Imputation mice (variables démographiques) ──")
individus <- impute_mice(individus, vars = MICE_VARS_IND,
                         method = "pmm", m = 5, seed = 42)

# ── Étape 3 : Construction table ménages ─────────────────────────────────────
message("\n══════════════════════════════════════════════════════════")
message("[3] Construction de la table ménages")
message("══════════════════════════════════════════════════════════")
source(file.path(R_DIR, "03_menages.R"), encoding = "UTF-8")
menages <- build_menages(raw, individus)

# Nettoyage paramétrique ménages
message("\n── Nettoyage ménages (run_cleaning_pipeline) ──")
menages <- run_cleaning_pipeline(menages, CLEANING_PARAMS_MEN, label = "Ménages")

# ── Étape 4 : QAQC ───────────────────────────────────────────────────────────
message("\n══════════════════════════════════════════════════════════")
message("[4] Construction du rapport QAQC")
message("══════════════════════════════════════════════════════════")
source(file.path(R_DIR, "04_qaqc.R"), encoding = "UTF-8")
qaqc <- build_qaqc(individus, menages)

# ── Étape 5 : Sauvegarde des tables output ────────────────────────────────────
message("\n══════════════════════════════════════════════════════════")
message("[5] Sauvegarde des outputs")
message("══════════════════════════════════════════════════════════")

# CSV (data.table::fwrite pour la rapidité)
data.table::fwrite(individus, file.path(OUTPUT_DIR, "individus.csv"))
data.table::fwrite(menages,   file.path(OUTPUT_DIR, "menages.csv"))
message("individus.csv : ", nrow(individus), " lignes x ", ncol(individus), " colonnes")
message("menages.csv   : ", nrow(menages),   " lignes x ", ncol(menages),   " colonnes")

# Excel QAQC multi-onglets (seulement les data.frames de la liste)
qaqc_tables <- Filter(function(x) is.data.frame(x), qaqc)
writexl::write_xlsx(qaqc_tables, file.path(OUTPUT_DIR, "QAQC.xlsx"))
message("QAQC.xlsx : ", length(qaqc_tables), " feuilles")

# ── Étape 6 : Rendu HTML complet (pipeline.Rmd) ───────────────────────────────
message("\n══════════════════════════════════════════════════════════")
message("[6] Rendu du rapport HTML (pipeline.Rmd)")
message("══════════════════════════════════════════════════════════")

# Localisation Pandoc (RStudio bundlé)
pandoc_dir <- "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools"
if (dir.exists(pandoc_dir)) {
  Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
  rmarkdown::find_pandoc(cache = FALSE, dir = pandoc_dir)
}

rmd_path <- file.path(BASE_DIR, "pipeline.Rmd")
if (file.exists(rmd_path) && rmarkdown::pandoc_available()) {
  rmarkdown::render(
    input         = rmd_path,
    output_format = "html_document",
    output_file   = file.path(OUTPUT_DIR, "QAQC_Report.html"),
    quiet         = FALSE,
    envir         = new.env(parent = globalenv())
  )
  message("QAQC_Report.html disponible dans le dossier output")
} else {
  message("Attention : Pandoc non disponible, le rapport HTML n'a pas pu être produit.")
  message("  Ouvrir pipeline.Rmd dans RStudio et cliquer sur Knit.")
}

message("\n══════════════════════════════════════════════════════════")
message("Pipeline terminé. Outputs dans : ", OUTPUT_DIR)
message("══════════════════════════════════════════════════════════\n")

# Le rapport d'analyse Word (rapport_word.Rmd) est indépendant du pipeline.
# Il se lit sur les tables consolidées produites ci-dessus : pour l'obtenir,
# ouvrir rapport_word.Rmd et cliquer sur Knit.
