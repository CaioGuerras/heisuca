# Fixture de TLS (somente teste)

`selfsigned_cert.pem` / `selfsigned_key.pem`: par autoassinado para 127.0.0.1,
gerado com openssl (RSA 2048, 100 anos) apenas para `test/security/servidor_malicioso_tls_test.dart`.
Não é segredo de ninguém e não é confiável em lugar nenhum: o teste prova que o
app RECUSA este certificado. Nunca usar fora de teste.
