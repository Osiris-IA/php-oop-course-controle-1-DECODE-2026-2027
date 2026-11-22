#!/bin/bash
# Tests des routes /contact (exercices 1 à 5)
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

echo "=== Exo 4 : PATCH /contact/{id} (mise à jour) ==="
# Un contact dédié aux tests 39 à 59 : il est modifié ici, puis supprimé par l'exo 5
curl -s -o /dev/null -X POST "$BASE/contact" -H "$J" \
    -d '{"email":"patch@test.com","subject":"Old subject","message":"Old message"}'
PID=$(ls "$CONTACTS_DIR" 2>/dev/null | grep '_patch@test\.com\.json$' | tail -1 | sed 's/\.json$//')
PTS=${PID%%_*}   # le timestamp du nom de fichier = dateOfCreation
if [ -z "$PID" ]; then
    ko "39-59. impossible de créer le contact de test patch@test.com"
else
    check        "39. PATCH subject seul → 200"         200 PATCH "/contact/$PID" -H "$J" -d '{"subject":"New subject"}'
    check_header "40. PATCH en application/json"        "Content-Type: application/json" PATCH "/contact/$PID" -H "$J" -d '{"subject":"New subject"}'
    check_body   "41. body = un objet {...}"            '^\{.*\}$' PATCH "/contact/$PID" -H "$J" -d '{"subject":"New subject"}'
    check_body   "42. subject modifié"                  '"subject":"New subject"' GET "/contact/$PID" -H "$J"
    check_body   "43. email et message conservés"       '"email":"patch@test\.com".*"message":"Old message"' GET "/contact/$PID" -H "$J"
    check_body   "44. dateOfCreation inchangée"         "\"dateOfCreation\":$PTS[,}]" GET "/contact/$PID" -H "$J"
    check_body   "45. body contient les 5 clés"         'email.*subject.*message.*dateOfCreation.*dateOfLastUpdate' GET "/contact/$PID" -H "$J"
    if grep -q '"subject": "New subject"' "$CONTACTS_DIR/$PID.json"; then
        ok "46. fichier mis à jour sur le disque"
    else
        ko "46. fichier mis à jour sur le disque → $(head -c 120 "$CONTACTS_DIR/$PID.json")"
    fi
    # dateOfLastUpdate : on attend 1 s pour être sûr que time() a changé
    sleep 1
    curl -s -o /dev/null -X PATCH "$BASE/contact/$PID" -H "$J" -d '{"message":"New message"}'
    LAST=$(grep -o '"dateOfLastUpdate": [0-9]*' "$CONTACTS_DIR/$PID.json" | grep -o '[0-9]*$')
    if [ -n "$LAST" ] && [ "$LAST" -gt "$PTS" ]; then
        ok "47. dateOfLastUpdate mise à jour ($PTS → $LAST)"
    else
        ko "47. dateOfLastUpdate mise à jour → $LAST (création : $PTS)"
    fi
    check        "48. PATCH les 3 clés → 200"           200 PATCH "/contact/$PID" -H "$J" -d '{"email":"patch@test.com","subject":"S3","message":"M3"}'
    check_body   "49. les 3 valeurs modifiées"          '"subject":"S3","message":"M3"' GET "/contact/$PID" -H "$J"
    check        "50. clé en trop (recipient) → 400"    400 PATCH "/contact/$PID" -H "$J" -d '{"subject":"x","recipient":"r2d2@robot.com"}'
    check_body   "51. clé en trop : fichier intact"     '"subject":"S3"' GET "/contact/$PID" -H "$J"
    check        "52. JSON cassé → 400"                 400 PATCH "/contact/$PID" -H "$J" -d '{subject: cassé'
    check        "53. JSON pas un tableau → 400"        400 PATCH "/contact/$PID" -H "$J" -d '"coucou"'
    check        "54. sans content-type → 400"          400 PATCH "/contact/$PID" -d '{"subject":"x"}'
    check        "55. contact inexistant → 404"         404 PATCH /contact/0_nobody@nowhere.com -H "$J" -d '{"subject":"x"}'
    check        "56. PATCH /contact sans id → 405"     405 PATCH /contact -H "$J" -d '{"subject":"x"}'
    check        "57. PUT /contact/{id} refusé → 405"   405 PUT "/contact/$PID" -H "$J" -d '{"subject":"x"}'

    echo "=== Exo 5 : DELETE /contact/{id} (suppression) ==="
    check        "58. sans content-type → 400"          400 DELETE "/contact/$PID"
    if [ -f "$CONTACTS_DIR/$PID.json" ]; then
        ok "59. sans content-type : fichier toujours là"
    else
        ko "59. sans content-type : le fichier a été supprimé !"
    fi
    DEL=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE/contact/$PID" -H "$J")
    DEL_CODE=$(echo "$DEL" | tail -1)
    DEL_BODY=$(echo "$DEL" | sed '$d')
    if [ "$DEL_CODE" = "204" ]; then ok "60. DELETE → 204"; else ko "60. DELETE → attendu 204, obtenu $DEL_CODE"; fi
    if [ -z "$DEL_BODY" ]; then ok "61. DELETE : aucun contenu"; else ko "61. DELETE : contenu reçu : $(echo "$DEL_BODY" | head -c 120)"; fi
    if [ ! -f "$CONTACTS_DIR/$PID.json" ]; then
        ok "62. fichier supprimé du disque"
    else
        ko "62. fichier supprimé du disque → il existe encore"
    fi
    check        "63. 2ᵉ DELETE → 404"                  404 DELETE "/contact/$PID" -H "$J"
    check        "64. GET après DELETE → 404"           404 GET "/contact/$PID" -H "$J"
    check        "65. PATCH après DELETE → 404"         404 PATCH "/contact/$PID" -H "$J" -d '{"subject":"x"}'
    check        "66. DELETE /contact sans id → 405"    405 DELETE /contact -H "$J"
fi

echo
echo "Résultat : $PASS réussi(s), $FAIL échoué(s)"
