import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime

# --- CONFIGURATION ---
# 1. Téléchargez votre clé de service (JSON) depuis la console Firebase :
#    Paramètres du projet > Comptes de service > Générer une nouvelle clé privée
# 2. Renommez-le 'serviceAccountKey.json' et placez-le dans ce dossier.
SERVICE_ACCOUNT_PATH = 'serviceAccountKey.json'

try:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Connecté à FireStore avec succès.")
except Exception as e:
    print(f"❌ Erreur de connexion : {e}")
    print("Veuillez vérifier que 'serviceAccountKey.json' est présent.")
    exit()

# --- DONNÉES RÉELLES (Mali) ---
agences = [
    {
        "id": "a1",
        "nom": "Sira Bank - Siège (ACI 2000)",
        "adresse": "Avenue du Mali, Bamako",
        "ville": "Bamako",
        "latitude": 12.6392,
        "longitude": -8.0267,
        "enAttenteCount": 0,
        "isOpen": True
    },
    {
        "id": "a2",
        "nom": "Sira Bank - Badalabougou",
        "adresse": "Près de l'Ambassade d'Allemagne",
        "ville": "Bamako",
        "latitude": 12.6186,
        "longitude": -7.9961,
        "enAttenteCount": 0,
        "isOpen": True
    },
    {
        "id": "a3",
        "nom": "Sira Bank - Magnambougou",
        "adresse": "Boulevard de la CEDEAO",
        "ville": "Bamako",
        "latitude": 12.6072,
        "longitude": -7.9467,
        "enAttenteCount": 0,
        "isOpen": True
    }
]

guichets = [
    {"agence_id": "a1", "numero": 1, "statut": "open"},
    {"agence_id": "a1", "numero": 2, "statut": "open"},
    {"agence_id": "a1", "numero": 3, "statut": "closed"},
    {"agence_id": "a2", "numero": 1, "statut": "open"},
]

def seed_database():
    print("🚀 Injection des données en cours...")
    
    # 1. Injecter les agences
    for ag in agences:
        doc_ref = db.collection('agences').document(ag['id'])
        doc_ref.set(ag)
        print(f"   📍 Agence ajoutée : {ag['nom']}")

    # 2. Injecter les guichets
    for gu in guichets:
        db.collection('guichets').add(gu)
        print(f"   🪟 Guichet {gu['numero']} ajouté pour l'agence {gu['agence_id']}")

    print("\n✨ Base de données peuplée avec succès !")

if __name__ == "__main__":
    seed_database()
