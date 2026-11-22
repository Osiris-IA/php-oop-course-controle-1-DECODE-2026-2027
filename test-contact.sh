#!/bin/bash
# Tests des routes /contact (exercices 1, 2 et 3)
# Utilisation : bash test-contact.sh  (à lancer depuis la racine du projet)

BASE=127.0.0.1:8080
J="Content-Type: application/json"
CONTACTS_DIR=app/var/contacts
PASS=0
FAIL=0

ok()  { echo "✅ $1"; PASS=$((PASS + 1)); }
ko()  { echo "❌ $1"; FAIL=$((FAIL + 1)); }

# check "description" code_attendu METHODE chemin [options curl...]
check() {
    local label="$1" expected="$2" method="$3" path="$4"
    shift 4
    local got
    got=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE$path" "$@")
    if [ "$got" = "$expected" ]; then
        ok "$label → $got"
    else
        ko "$label → attendu $expected, obtenu $got"
    fi
}

# check_body "description" "regex attendue dans le body" METHODE chemin [options curl...]
check_body() {
    local label="$1" pattern="$2" method="$3" path="$4"
    shift 4
    local body
    body=$(curl -s -X "$method" "$BASE$path" "$@")
    if echo "$body" | grep -Eq "$pattern"; then
        ok "$label"
    else
        ko "$label → body reçu : $(echo "$body" | head -c 120)"
    fi
}

# check_header "description" "header attendu" METHODE chemin [options curl...]
check_header() {
    local label="$1" pattern="$2" method="$3" path="$4"
    shift 4
    if curl -s -D - -o /dev/null -X "$method" "$BASE$path" "$@" | grep -iq "$pattern"; then
        ok "$label"
    else
        ko "$label → header « $pattern » absent"
    fi
}

VALID='{"email":"a@b.com","subject":"Hi","message":"Hello"}'

echo "=== Exo 1 : POST /contact, cas valides ==="
check "1. contact valide"                 201 POST /contact -H "$J" -d "$VALID"
check "9. subject \"0\""                  201 POST /contact -H "$J" -d '{"email":"a@b.com","subject":"0","message":"Hello"}'
check "11. clés dans un autre ordre"      201 POST /contact -H "$J" -d '{"message":"Hello","email":"a@b.com","subject":"Hi"}'
check "12. content-type avec charset"     201 POST /contact -H "Content-Type: application/json; charset=utf-8" -d "$VALID"

echo "=== Exo 1 : A. Content-Type ==="
check "13. content-type text/plain"       400 POST /contact -H "Content-Type: text/plain" -d "$VALID"
check "14. sans content-type"             400 POST /contact -d "$VALID"

echo "=== Exo 1 : B. JSON valide ==="
check "15. JSON cassé"                    400 POST /contact -H "$J" -d '{email: cassé'
check "16. JSON pas un tableau"           400 POST /contact -H "$J" -d '"coucou"'
check "17. body vide"                     400 POST /contact -H "$J" -d ''

echo "=== Exo 1 : C. Clés ==="
check "2. clé en trop"                    400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":"Hello","recipient":"x"}'
check "3. clé manquante"                  400 POST /contact -H "$J" -d '{"email":"a@b.com","message":"Hello"}'
check "18. objet vide {}"                 400 POST /contact -H "$J" -d '{}'
check "19. liste au lieu d'objet"         400 POST /contact -H "$J" -d '["email","subject","message"]'

echo "=== Exo 1 : D. Valeurs ==="
check "4. email nombre"                   400 POST /contact -H "$J" -d '{"email":42,"subject":"Hi","message":"Hello"}'
check "5. email invalide"                 400 POST /contact -H "$J" -d '{"email":"coucou","subject":"Hi","message":"Hello"}'
check "20. email chemin de fichier"       400 POST /contact -H "$J" -d '{"email":"../../x","subject":"Hi","message":"Hello"}'
check "6. subject vide"                   400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":"","message":"Hello"}'
check "21. subject nombre"                400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":123,"message":"Hello"}'
check "22. subject tableau"               400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":["x"],"message":"Hello"}'
check "7. message espaces"                400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":"   "}'
check "8. message null"                   400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":null}'
check "10. message vide"                  400 POST /contact -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":""}'

echo "=== Router : uri avec paramètre ==="
check "23. GET / (home) toujours OK"      200 GET /
check "24. /hello inconnue"               404 GET /hello -H "$J"
check "25. /hello/abc inconnue"           404 GET /hello/abc -H "$J"
check "26. /contact/abc/def trop long"    404 GET /contact/abc/def -H "$J"
check "27. PUT /contact méthode refusée"  405 PUT /contact -H "$J"

echo "=== Exo 2 : GET /contact (liste) ==="
check        "28. liste → 200"                    200 GET /contact -H "$J"
check        "29. liste sans content-type → 400"  400 GET /contact
check_header "30. liste en application/json"      "Content-Type: application/json" GET /contact -H "$J"
check_body   "31. liste = tableau JSON [...]"     '^\[.*\]$' GET /contact -H "$J"
check_body   "32. liste contient a@b.com"         '"email":"a@b\.com"' GET /contact -H "$J"

echo "=== Exo 3 : GET /contact/{id} (un contact) ==="
# On prend un VRAI fichier sauvegardé (le test 1 en a créé un), sans l'extension .json
# (Apache ne passe pas à PHP les uris qui finissent par .json, cf. app/.htaccess)
ID=$(ls "$CONTACTS_DIR" 2>/dev/null | grep '\.json$' | head -1 | sed 's/\.json$//')
if [ -z "$ID" ]; then
    ko "33-38. aucun contact dans $CONTACTS_DIR, tests de l'exo 3 impossibles"
else
    check        "33. contact existant → 200"           200 GET "/contact/$ID" -H "$J"
    check_header "34. contact en application/json"      "Content-Type: application/json" GET "/contact/$ID" -H "$J"
    check_body   "35. body = un objet {...}"            '^\{.*\}$' GET "/contact/$ID" -H "$J"
    check_body   "36. body contient les 5 clés"         'email.*subject.*message.*dateOfCreation.*dateOfLastUpdate' GET "/contact/$ID" -H "$J"
    check        "37. contact inexistant → 404"         404 GET /contact/0_nobody@nowhere.com -H "$J"
    # Sécurité : selon la config d'Apache, il peut bloquer avant PHP (404 aussi)
    check        "38. traversée ..%2F → 404"            404 GET /contact/..%2F..%2Fconfig%2Froutes -H "$J"
fi

echo
echo "Résultat : $PASS réussi(s), $FAIL échoué(s)"
