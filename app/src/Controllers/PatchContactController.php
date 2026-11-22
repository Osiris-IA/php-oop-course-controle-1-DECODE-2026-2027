<?php

namespace App\Controllers;

use Lib\Http\Request;
use Lib\Http\Response;
use Lib\Controllers\AbstractController;

class PatchContactController extends AbstractController
{
    private const string SAVE_CONTACT_PATH = __DIR__ . '/../../var/contacts/';
    public function process(Request $request): Response
    {
        $response = new Response();
        $response->headers = ['Content-Type: application/json'];
        $contentType = $request->getHeaders()['Content-Type'] ?? '';

        if (stripos($contentType, 'application/json') === false) {
            $response->statusCode = 400;
            $response->content = json_encode(['error' => 'Content-Type must be application/json']);
            return $response;
        }

        $fileNameSecurise = basename($request->getId());

        $filePath = self::SAVE_CONTACT_PATH . $fileNameSecurise . ".json";

        if (file_exists($filePath) === false) {
            $response->statusCode = 404;
            $response->content = json_encode(['error' => 'Contact not found']);
            return $response;
        }

        $filePathContent = file_get_contents($filePath);
        $filePathDecode = json_decode($filePathContent, true, 512, JSON_THROW_ON_ERROR);
        
        $data = json_decode($request->getBody(), true);

        if (!is_array($data)) {
            $response->statusCode = 400;
            $response->content = json_encode(['error' => 'Invalid JSON body']);
            return $response;
        }
        $allowedKeys = ['email', 'subject', 'message'];

        foreach ($data as $key => $value) {
            if (!in_array($key, $allowedKeys)) {
                $response->statusCode = 400;
                $response->content = json_encode(['error' => 'Property not allowed: ' . $key]);
                return $response;
            }
        }

        $contactUpdate = array_merge($filePathDecode, $data);

        $contactUpdate['dateOfLastUpdate'] = time();

        $result = file_put_contents($filePath, json_encode($contactUpdate, JSON_PRETTY_PRINT));

        if ($result === false) {
            $response->statusCode = 500;
            $response->content = json_encode(['error' => 'Could not save contact']);
            return $response;
        }



        $response->statusCode = 200;
        $response->content = json_encode($contactUpdate);

        return $response;
    }
}
