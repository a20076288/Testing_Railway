# ✅ 1. Usar a imagem oficial do PHP 8.3 com FPM
FROM php:8.3-fpm

# ✅ 2. Definir diretório de trabalho
WORKDIR /var/www/html

# ✅ 3. Instalar extensões necessárias para o Laravel
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    git \
    curl \
    nano \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo_mysql mbstring bcmath intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ✅ 4. Instalar Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# ✅ 5. Criar projeto base Laravel (porque o teu repositório tem só código personalizado)
RUN composer create-project --prefer-dist laravel/laravel .

# ✅ 6. Copiar o código personalizado (app, routes, config, etc.)
COPY ./app /var/www/html/app
COPY ./config /var/www/html/config
COPY ./database /var/www/html/database
COPY ./public /var/www/html/public
COPY ./resources /var/www/html/resources
COPY ./routes /var/www/html/routes
COPY composer.json composer.lock ./

# ✅ 7. Instalar dependências do Laravel e plugins (Filament, Spatie, Saad Calendar)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# ✅ 8. Gerar e Mostrar a APP_KEY nos logs do Railway
RUN php artisan key:generate --show \
    && php artisan key:generate --force \
    && echo "APP_KEY gerada: $(php artisan key:generate --show)"

# ✅ 9. Definir variáveis de ambiente para a base de dados (Railway)
ARG MYSQLHOST
ARG MYSQLPORT
ARG MYSQLUSER
ARG MYSQLPASSWORD
ARG MYSQLDATABASE

ENV DB_CONNECTION=mysql
ENV DB_HOST=$MYSQLHOST
ENV DB_PORT=$MYSQLPORT
ENV DB_DATABASE=$MYSQLDATABASE
ENV DB_USERNAME=$MYSQLUSER
ENV DB_PASSWORD=$MYSQLPASSWORD

# Adicionar o script de espera
COPY wait-for-db.sh /wait-for-db.sh
RUN chmod +x /wait-for-db.sh

# Executar script de espera antes das migrações
RUN /wait-for-db.sh \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan storage:link \
    && php artisan migrate --force \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache


# ✅ 11. Corrigir permissões
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# ✅ 12. Expor a porta padrão do PHP-FPM
EXPOSE 8080

# ✅ 13. Comando para iniciar o servidor
CMD ["php", "-S", "0.0.0.0:8080", "-t", "public"]
