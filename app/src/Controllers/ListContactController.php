<?php

namespace App\Controllers;

use Lib\Http\Request;
use Lib\Http\Response;
use Lib\Controllers\AbstractController;

class ListContactController extends AbstractController
{
    private const string SAVE_CONTACT_PATH = __DIR__ . '/../../var/contacts/';

    public function process(Request $request): Response
    {
        if (!is_dir(self::SAVE_CONTACT_PATH)) {
            $response = new Response();
            $response->headers = ['Content-Type: application/json'];
            $contentType = $request->getHeaders()['Content-Type'] ?? '';
            if (stripos($contentType, 'application/json') === false) {
                $response->statusCode = 400;
                $response->content = json_encode(['error' => 'Content-Type must be application/json']);
                return $response;
            }
            $response->statusCode = 200;
            $response->content = json_encode([]);

            return $response;
        }

        $files = glob(self::SAVE_CONTACT_PATH . "*.json");

        $currentContacts = [];
        foreach ($files as $file) {
            $fileContent = file_get_contents($file);
            $fileContactDecode = json_decode($fileContent, true, 512, JSON_THROW_ON_ERROR);

            $currentContacts[] = $fileContactDecode;
        }


        $response = new Response();
        $response->statusCode = 200;
        $response->content = json_encode(
            [
                "Contact" => $currentContacts
            ]
        );

        return $response;
    }
}
