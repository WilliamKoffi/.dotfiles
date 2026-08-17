return {
  "phpactor/phpactor",
  ft = "php", -- Load only for PHP files
  build = "composer install --no-dev -o", -- Run this command after installation
}
