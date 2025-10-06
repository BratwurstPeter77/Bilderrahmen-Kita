<?php
/*
 * Bilderrahmen-Kita - Foto API mit Monats-Sortierung
 * Copyright (c) 2025 BratwurstPeter77
 * Licensed under the MIT License
 * 
 * Diese Datei wird automatisch während der Installation generiert
 * mit den korrekten Gruppennamen und Pfaden.
 */

header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');

$folder = isset($_GET['folder']) ? $_GET['folder'] : 'default';
$month = isset($_GET['month']) ? $_GET['month'] : date('Y/m'); // Format: 2025/10 oder 'all'

// HINWEIS: Die erlaubten Ordner werden während der Installation automatisch gesetzt
// Beispiel: $allowedFolders = ['käfer', 'bienen', 'schmetterlinge', 'frösche', 'mäuse'];
$allowedFolders = ['käfer', 'bienen', 'schmetterlinge']; // Wird automatisch ersetzt

if (!in_array($folder, $allowedFolders)) {
    http_response_code(400);
    echo json_encode([
        'success' => false, 
        'error' => 'Ungültiger Ordner',
        'allowed' => $allowedFolders,
        'requested' => $folder
    ]);
    exit;
}

// Basis-Pfad zu den Fotos
$basePath = '/home/pi/Fotos/' . $folder; // Wird automatisch angepasst

// Wenn spezifischer Monat angefragt
if ($month && $month !== 'all') {
    $basePath .= '/' . $month;
}

// Ordner existiert?
if (!is_dir($basePath)) {
    echo json_encode([
        'success' => false, 
        'error' => 'Ordner nicht gefunden: ' . $basePath,
        'folder' => $folder,
        'month' => $month
    ]);
    exit;
}

// Bilder sammeln
$images = [];
$allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

/**
 * Rekursiv durch Ordner und Unterordner (Monate) scannen
 */
function scanImagesRecursive($dir, $relativePath = '') {
    global $images, $allowedExtensions;

    $files = scandir($dir);
    if ($files === false) return;

    foreach ($files as $file) {
        if ($file === '.' || $file === '..' || $file === 'README.txt') continue;

        $fullPath = $dir . '/' . $file;
        $relativeFile = $relativePath ? $relativePath . '/' . $file : $file;

        if (is_dir($fullPath)) {
            // Rekursiv in Unterordner (Jahr/Monat)
            scanImagesRecursive($fullPath, $relativeFile);
        } elseif (is_file($fullPath)) {
            $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
            if (in_array($ext, $allowedExtensions)) {
                $monthPath = dirname($relativeFile);
                if ($monthPath === '.') {
                    $monthPath = 'ungrouped';
                }

                $images[] = [
                    'name' => $file,
                    'path' => $relativeFile,
                    'size' => filesize($fullPath),
                    'modified' => filemtime($fullPath),
                    'month' => $monthPath,
                    'date' => date('Y-m-d H:i:s', filemtime($fullPath))
                ];
            }
        }
    }
}

// Bilder scannen
scanImagesRecursive($basePath);

// Nach Datum sortieren (neueste zuerst)
usort($images, function($a, $b) {
    return $b['modified'] - $a['modified'];
});

// Monats-Statistiken erstellen
$monthStats = [];
foreach ($images as $img) {
    $month = $img['month'];
    if (!isset($monthStats[$month])) {
        $monthStats[$month] = 0;
    }
    $monthStats[$month]++;
}

// Response zusammenstellen
$response = [
    'success' => true,
    'images' => $images,
    'count' => count($images),
    'folder' => $folder,
    'month' => $month,
    'basePath' => $basePath,
    'monthStats' => $monthStats,
    'generated' => date('Y-m-d H:i:s'),
    'version' => '1.0.0'
];

// Bei Debugging auch Pfad-Info hinzufügen
if (isset($_GET['debug']) && $_GET['debug'] === '1') {
    $response['debug'] = [
        'php_version' => PHP_VERSION,
        'server_time' => date('c'),
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'unknown',
        'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? 'unknown',
        'allowed_folders' => $allowedFolders
    ];
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>