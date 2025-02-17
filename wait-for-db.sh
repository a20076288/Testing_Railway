#!/bin/sh

echo "Aguardando pela base de dados..."

# Espera até a base de dados estar pronta
while ! nc -z "$DB_HOST" "$DB_PORT"; do
  echo "Base de dados não disponível. A aguardar..."
  sleep 2
done

echo "Base de dados encontrada! A prosseguir..."
