<?php

namespace App\Controllers;

use Lib\Http\Request;
use Lib\Http\Response;
use Lib\Controllers\AbstractController;

class DeleteContactController extends AbstractController
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

        $deleteFile = unlink($filePath);
        if ($deleteFile === false) {
            $response->statusCode = 500;
            $response->content = json_encode(['error' => 'Could not delete contact']);
            return $response;
        }

        $response->statusCode = 204;
        $response->content = "";

        return $response;
    }
}
