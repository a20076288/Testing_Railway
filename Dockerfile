# Usar a imagem oficial do PHP 8.3 com FPM
FROM php:8.3-fpm

# Instalar dependências do sistema e extensões PHP
# Instalar pacotes necessários
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
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo_mysql mbstring bcmath

RUN apt-get update && apt-get install -y libicu-dev && docker-php-ext-install intl

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

# Passo 1: Criar estrutura do Laravel completa (com dependências)
RUN composer create-project laravel/laravel tmp-laravel --no-interaction --no-scripts

# Passo 2: Remover pastas padrão que serão substituídas
RUN rm -rf tmp-laravel/app tmp-laravel/database tmp-laravel/config

# Passo 3: Copiar SEUS arquivos para dentro da estrutura
COPY . ./tmp-laravel

# Passo 4: Mover tudo para o diretório principal
RUN mv tmp-laravel/* . && mv tmp-laravel/.* . 2>/dev/null || true

# Passo 5: Instalar dependências adicionais
RUN composer install --ignore-platform-reqs --no-scripts

# Passo 6: Executar comandos pós-instalação
RUN composer run-script post-autoload-dump \
    && php artisan key:generate --force \
    && php artisan config:cache

# Configurar permissões
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Limpar arquivos temporários
RUN rm -rf tmp-laravel

CMD ["php-fpm"]