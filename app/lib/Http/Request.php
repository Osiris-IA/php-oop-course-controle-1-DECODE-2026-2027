<?php

namespace Lib\Http;

class Request
{
    private readonly string $uri;
    private readonly string $method;
    private readonly array $headers;
    private readonly string $body;
    private readonly string $id;

    public function __construct()
    {
        $this->uri = $_SERVER['REQUEST_URI'];
        $this->method = $_SERVER['REQUEST_METHOD'];
        $this->headers = getallheaders();
        $this->body = file_get_contents('php://input');
    }

    public function getUri(): string
    {
        return $this->uri;
    }

    public function getMethod(): string
    {
        return $this->method;
    }

    public function getHeaders(): array
    {
        return $this->headers;
    }

    public function getBody(): string
    {
        return $this->body;
    }
    public function getId(): string
    {
        return $this->id;
    }
    public function setId(string $id): void
    {
        $this->id = $id;
    }
}
