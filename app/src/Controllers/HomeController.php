<?php

namespace App\Controllers;

use Lib\Http\Request;
use Lib\Http\Response;
use Lib\Controllers\AbstractController;

class HomeController extends AbstractController {
    public function process(Request $request): Response {
        $response = new Response();
        $response->statusCode = 200;
        $response->content = 'success';

        return $response;
    }
}

?>

