<?php

namespace App\Controllers;

use Lib\Http\Request;
use Lib\Http\Response;
use Lib\Controllers\AbstractController;

class ContactController extends AbstractController
{
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

        if(!is_array($data)) {
            $response->statusCode = 400;
            $response->content = json_encode(['error' => 'Invalid JSON body']);
            return $response;
        }
        $response->statusCode = 200;
        $response->content = print_r($data, true);

        return $response;
    }

    // private function decodeBody(string $data): array {
        
    //     return json_decode($data, true, 512, JSON_THROW_ON_ERROR);
    // }



    
}
