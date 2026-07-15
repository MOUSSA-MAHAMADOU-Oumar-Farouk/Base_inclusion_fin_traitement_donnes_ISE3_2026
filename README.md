<<<<<<< HEAD
# Pipeline Inclusion Financière BCEAO · Sénégal

Traitement des données de l'enquête BCEAO sur l'inclusion financière.  
Produit deux tables consolidées (individus et ménages) et un fichier QAQC.

**Auteurs :** Anna A. JOYCE, Bocar M. DIACK, Wendvi A. D. MANDO, Oumar FAROUK, Saran NDIAYE

---

## Aucun chemin à configurer

Le pipeline détecte tout seul la racine du projet à partir de l'emplacement de
`run_all.R`, et repère le dossier des données brutes parmi `données/base`,
`donnees/base` ou `input`. Le projet peut donc être déplacé, renommé ou copié
sur une autre machine sans modifier une seule ligne de code.

Il suffit que les fichiers `.dta` soient dans l'un de ces dossiers, et de lancer
`run_all.R` depuis n'importe quel répertoire de travail.

---

## Prérequis

| Logiciel | Version minimale | Lien |
|----------|-----------------|------|
| R | 4.3 ou supérieur | https://cran.r-project.org/ |
| RStudio | 2023 ou supérieur | https://posit.co/download/rstudio-desktop/ |
| Connexion internet | Au premier lancement | Installation automatique des packages |

> **RStudio est obligatoire** (ou Positron). Un terminal R seul ne suffit pas car  
> Pandoc (inclus dans RStudio) est nécessaire pour générer les rapports HTML et Word.

---

## Structure des fichiers attendue

```
Traitements de données/          ← dossier racine (BASE_DIR)
│
├── run_all.R                    ← POINT D'ENTRÉE : lancer ce fichier uniquement
│
├── R/
│   ├── 00_config.R              ← SEUL FICHIER À MODIFIER (chemins + paramètres)
│   ├── 00c_fill_dict.R          ← Génère les dictionnaires de variables (auto)
│   ├── 01_load_data.R           ← Chargement des .dta
│   ├── 02_individus.R           ← Table individus (blocs A à K)
│   ├── 03_menages.R             ← Table ménages
│   ├── 04_qaqc.R                ← Rapport qualité
│   └── utils.R                  ← Fonctions de traitement (dictionnaires, nettoyage, imputation)
│
├── Données/base/                ← Mettre ici les fichiers .dta source
│   ├── membres.dta
│   ├── menageincbceaov01.dta
│   └── (autres fichiers .dta…)
│
├── data/aux_file/               ← Dictionnaires de variables (créés par le pipeline)
│   ├── membres_dict.csv
│   └── menage_dict.csv
│
├── output/                      ← Fichiers produits par le pipeline
│   ├── individus.csv
│   ├── menages.csv
│   ├── QAQC.xlsx
│   └── QAQC_Report.html
│
├── pipeline.Rmd                 ← Rapport HTML (rendu par run_all.R)
└── rapport_word.Rmd             ← Rapport d'analyse Word (indépendant : à knitter au besoin)
```

---

## Lancement

### 1. Vérifier que les fichiers .dta sont bien en place

Les fichiers `.dta` doivent se trouver dans `données/base/` (ou `donnees/base/`,
ou `input/`). Le pipeline choisit automatiquement celui qui contient des `.dta`.

### 2. Lancer le pipeline

**Option A - depuis l'éditeur RStudio (recommandé) :**

Ouvrir `run_all.R`, puis cliquer sur le bouton **Source** (en haut à droite de l'éditeur).

**Option B - en ligne de commande, depuis le dossier du projet :**

```bash
Rscript run_all.R
```

Le pipeline tourne en **5 à 10 minutes** selon la machine (l'imputation MICE est l'étape la plus longue).

### 3. Vérifier les outputs

À la fin, le message suivant s'affiche :

```
Pipeline terminé. Outputs dans : C:/…/output
```

Les fichiers produits se trouvent dans le dossier `output/`.

---

## Outputs produits

| Fichier | Description |
|---------|-------------|
| `individus.csv` | 8 266 individus × 79 variables (démographie, emploi, inclusion financière) |
| `menages.csv` | 1 298 ménages × 61 variables (géographie, conditions de vie, agrégats financiers) |
| `QAQC.xlsx` | 20 feuilles : complétude, cohérence, taux d'inclusion par genre/milieu/région |
| `QAQC_Report.html` | Rapport qualité avec graphiques (ouvrir dans un navigateur) |

---

## Rapport d'analyse Word (optionnel)

`rapport_word.Rmd` ne fait pas partie du pipeline. C'est un document d'analyse qui relit
les tables consolidées de `output/` : il faut donc avoir lancé `run_all.R` au moins une fois.

Pour l'obtenir : ouvrir `rapport_word.Rmd` dans RStudio et cliquer sur **Knit**.
Le fichier `rapport_word.docx` est alors créé à côté du Rmd.

---

## Erreurs fréquentes

### `objet 'X' introuvable`
Le fichier `.dta` correspondant est absent de `Données/base/`.  
Vérifier que tous les fichiers `.dta` sont présents et que `INPUT_DIR` dans `00_config.R` pointe vers le bon dossier.

### `LaTeX failed to compile`
Ne pas utiliser `knit` directement sur `pipeline.Rmd` ou `rapport_word.Rmd`.  
Toujours passer par `run_all.R` qui force le rendu en HTML/Word (pas PDF).

### `Pandoc not found` ou rapport non généré
RStudio doit être installé. Ouvrir RStudio et relancer depuis la console RStudio.

### `NAs introduits lors de la conversion automatique`
Avertissement normal - certaines valeurs manquantes (`##N/A##`) dans Survey Solutions  
sont converties en `NA` R. Ce n'est pas une erreur.

### Les dictionnaires CSV sont vides ou absents
Supprimer `data/aux_file/membres_dict.csv` et `data/aux_file/menage_dict.csv`,  
puis relancer `run_all.R`. Ils seront recréés au lancement suivant.

---

## Modifier les variables conservées (approche dictionnaire)

Les dictionnaires `data/aux_file/membres_dict.csv` et `menage_dict.csv`  
contrôlent quelles variables sont gardées et comment elles sont renommées.

| Colonne | Rôle | Valeurs |
|---------|------|---------|
| `var_orig` | Nom brut dans le .dta | ex. `s02q06` |
| `var_new` | Nouveau nom normalisé | ex. `actif_occupe` |
| `type_new` | Type R cible | `numeric`, `integer`, `character`, `factor` |
| `keep` | Conserver ? | `1` = oui · `0` = non |
| `label_new` | Libellé descriptif | ex. `Exerce une activité principale` |

**Pour ajouter une variable :**
1. Ouvrir le CSV dans Excel
2. Trouver la ligne avec le nom brut Stata (`var_orig`)
3. Mettre `keep = 1`, remplir `var_new` et `type_new`
4. Sauvegarder et relancer `run_all.R`

**Pour régénérer les dictionnaires depuis zéro** (nouveau round d'enquête) :

```r
# Supprimer les CSV, puis :
source("R/00c_fill_dict.R", encoding = "UTF-8")
fill_all_dicts()
```

---

## Nouveau round d'enquête - checklist

- [ ] Copier les nouveaux fichiers `.dta` dans `données/base/`
- [ ] Supprimer `data/aux_file/membres_dict.csv` et `menage_dict.csv`
- [ ] Relancer `run_all.R` - les dictionnaires seront recréés
- [ ] Vérifier les mappings dans les CSV si des variables ont changé entre rounds
- [ ] Relancer `run_all.R` pour la production finale

---

## Paramètres calibrables (`R/00_config.R`)

```r
OUTLIER_IQR_FACTOR <- 3      # seuil de détection des valeurs extrêmes
AGE_MIN_CONSENT    <- 15     # âge minimum pour l'analyse
AGE_MAX_PLAUSIBLE  <- 120

MICE_VARS_IND <- c("age", "niv_etudes", "sit_matrimoniale")  # variables imputées par MICE
```

---

*Données : Enquête BCEAO sur l'Inclusion Financière, Sénégal.*
=======
# Projet_Traitement_de_donnees_ISE3_2026_Base_I_finance
>>>>>>> 71b3bec64cdce7de571faa38b487c6b05a2be33d
