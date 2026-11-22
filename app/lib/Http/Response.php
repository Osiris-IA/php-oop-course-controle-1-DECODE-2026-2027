<?php

namespace Lib\Http;

class Response
{
    public int $statusCode;
    public string $content;
    public array $headers = [];

    public function getStatusCode(): int
    {
        return $this->statusCode;
    }

    public function getContent(): string
    {
        return $this->content;
    }

    public function getHeaders(): array
    {
        return $this->headers;
    }
}
