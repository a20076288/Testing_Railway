# Usar a imagem oficial do PHP 8.3 com FPM
FROM php:8.3-fpm

# Instalar dependências do sistema e extensões PHP
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo_mysql mbstring bcmath intl

# Instalar o Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Definir diretório de trabalho
WORKDIR /var/www/html

# Copiar APENAS composer.json e composer.lock primeiro (para cache de dependências)
COPY composer.json composer.lock ./

# Instalar dependências do Composer (sem scripts para evitar erros)
RUN composer install --ignore-platform-reqs --no-scripts --no-autoloader

# Copiar o restante do projeto
COPY . .

# Criar projeto Laravel dentro do container (substituindo app/database)
RUN composer create-project laravel/laravel tmp-laravel --no-interaction \
    && rm -rf tmp-laravel/app tmp-laravel/database \
    && mv app tmp-laravel/app \
    && mv database tmp-laravel/database \
    && mv tmp-laravel/* . \
    && rm -rf tmp-laravel

# Gerar autoloader otimizado e executar scripts do Laravel
RUN composer dump-autoload --optimize \
    && composer run-script post-autoload-dump

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html/storage \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expor a porta do PHP-FPM
EXPOSE 9000

# Comando de inicialização (PHP-FPM + Nginx)
CMD ["php-fpm"]