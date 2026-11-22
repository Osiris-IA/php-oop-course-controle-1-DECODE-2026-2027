#!/bin/bash
# Tests de la route POST /contact
# Utilisation : bash test-contact.sh

URL=127.0.0.1:8080/contact
J="Content-Type: application/json"
PASS=0
FAIL=0

# check "description" code_attendu [options curl...]
check() {
    local label="$1"
    local expected="$2"
    shift 2
    local got
    got=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" "$@")
    if [ "$got" = "$expected" ]; then
        echo "✅ $label → $got"
        PASS=$((PASS + 1))
    else
        echo "❌ $label → attendu $expected, obtenu $got"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Cas valides ==="
check "1. contact valide"                 201 -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":"Hello"}'
check "9. subject \"0\""                  201 -H "$J" -d '{"email":"a@b.com","subject":"0","message":"Hello"}'
check "11. clés dans un autre ordre"      201 -H "$J" -d '{"message":"Hello","email":"a@b.com","subject":"Hi"}'
check "12. content-type avec charset"     201 -H "Content-Type: application/json; charset=utf-8" -d '{"email":"a@b.com","subject":"Hi","message":"Hello"}'

echo "=== A. Content-Type ==="
check "13. content-type text/plain"       400 -H "Content-Type: text/plain" -d '{"email":"a@b.com","subject":"Hi","message":"Hello"}'
check "14. sans content-type"             400 -d '{"email":"a@b.com","subject":"Hi","message":"Hello"}'

echo "=== B. JSON valide ==="
check "15. JSON cassé"                    400 -H "$J" -d '{email: cassé'
check "16. JSON pas un tableau"           400 -H "$J" -d '"coucou"'
check "17. body vide"                     400 -H "$J" -d ''

echo "=== C. Clés ==="
check "2. clé en trop"                    400 -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":"Hello","recipient":"x"}'
check "3. clé manquante"                  400 -H "$J" -d '{"email":"a@b.com","message":"Hello"}'
check "18. objet vide {}"                 400 -H "$J" -d '{}'
check "19. liste au lieu d'objet"         400 -H "$J" -d '["email","subject","message"]'

echo "=== D. Valeurs ==="
check "4. email nombre"                   400 -H "$J" -d '{"email":42,"subject":"Hi","message":"Hello"}'
check "5. email invalide"                 400 -H "$J" -d '{"email":"coucou","subject":"Hi","message":"Hello"}'
check "20. email chemin de fichier"       400 -H "$J" -d '{"email":"../../x","subject":"Hi","message":"Hello"}'
check "6. subject vide"                   400 -H "$J" -d '{"email":"a@b.com","subject":"","message":"Hello"}'
check "21. subject nombre"                400 -H "$J" -d '{"email":"a@b.com","subject":123,"message":"Hello"}'
check "22. subject tableau"               400 -H "$J" -d '{"email":"a@b.com","subject":["x"],"message":"Hello"}'
check "7. message espaces"                400 -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":"   "}'
check "8. message null"                   400 -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":null}'
check "10. message vide"                  400 -H "$J" -d '{"email":"a@b.com","subject":"Hi","message":""}'

echo
echo "Résultat : $PASS réussi(s), $FAIL échoué(s)"
