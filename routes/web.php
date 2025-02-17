<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::get('/db-info', function () {
    try {
        $connection = DB::connection();
        $database = $connection->getDatabaseName();
        return "Laravel está ligado à base de dados: {$database}";
    } catch (\Exception $e) {
        return "Erro de conexão: " . $e->getMessage();
    }
});
