<?php

namespace App\Controllers;

use Lib\Http\Request;
use Lib\Http\Response;
use Lib\Controllers\AbstractController;

class ContactController extends AbstractController
{
    private const string SAVE_CONTACT_PATH = __DIR__ . '/../../var/contacts/';

    public function process(Request $request): Response
    {
        $response = new Response();
        // $body = $request->getBody();
        // $data = $this->decodeBody($body);
        $response->headers = ['Content-Type: application/json'];
        $contentType = $request->getHeaders()['Content-Type'] ?? '';

        if (stripos($contentType, 'application/json') === false) {
            $response->statusCode = 400;
            $response->content = json_encode(['error' => 'Content-Type must be application/json']);
            return $response;
        }
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
        foreach ($allowedKeys as $allowedKey) {
            if (!array_key_exists($allowedKey, $data)) {
                $response->statusCode = 400;
                $response->content = json_encode(['error' => 'Missing property: ' . $allowedKey]);
                return $response;
            }
        }

        if (!is_string($data['email']) || !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $response->statusCode = 400;
            $response->content = json_encode(['error' => 'Invalid email']);
            return $response;
        }

        foreach (['subject', 'message'] as $field) {
            if (!is_string($data[$field]) || trim($data[$field]) === '') {
                $response->statusCode = 400;
                $response->content = json_encode(['error' => 'Invalid ' . $field]);
                return $response;
            }
        }

        $now = time();
        $contact = [
            "email" => $data['email'],
            "subject" => trim($data['subject']),
            "message" => trim($data['message']),
            "dateOfCreation" => $now,
            "dateOfLastUpdate" => $now
        ];

        if (!is_dir(self::SAVE_CONTACT_PATH)) {
            mkdir(self::SAVE_CONTACT_PATH, 0777, true);
        }

        $filename = $now . "_" . $contact['email'] . ".json";

        $result = file_put_contents(self::SAVE_CONTACT_PATH . $filename, json_encode($contact, JSON_PRETTY_PRINT));

        if ($result === false) {
            $response->statusCode = 500;
            $response->content = json_encode(['error' => 'Could not save contact']);
            return $response;
        }

        $date = date('Y-m-d_H-i-s', $now);
        $responseFilename = $date . "_" . $contact['email'] . ".json";


        $response->statusCode = 201;
        $response->content = json_encode(
            [
                'file' => $responseFilename
            ]
        );

        return $response;
    }



    // private function decodeBody(string $data): array {

    //     return json_decode($data, true, 512, JSON_THROW_ON_ERROR);
    // }




}
