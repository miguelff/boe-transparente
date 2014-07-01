BOE Transparente
----------------

Generador de enlaces a documentos públicos pertenecientes al Boletín Oficial del Estado (BOE) y no indexados por los robots de búsqueda

![screenshot](https://cloud.githubusercontent.com/assets/210307/3449972/9e4d2e34-0170-11e4-89af-a0e652123cce.jpg)

Motivación
----------

http://www.meneame.net/story/robots-txt-boe-google-no-indexe-condenas-indultos-corruptos

Cómo se usa
-----------

Ejecuta en un terminal 

```
bundle install && bundle exec ruby generate.rb
```

Tarda un poco, porque http://www.boe.es/robots.txt tiene más de 8000 entradas.

El fichero `index.html` contendrá la página web con los enlaces.

Características
---------------

* Se puede ejecutar periódicamente, y comprobará si el contenido de robots.txt ha cambiado. Sólo en ese caso regenerará el fichero `index.html`
* Algunos de los enlaces de robots.txt corresponden a búsquedas que alcanzan otros de los documentos ocultos. Estos enlaces son filtrados por el script. También se han filtrado enlaces duplicados (que apuntan al mismo contenido desde diferentes URLs)

### TO-DO

* Extracción de títulos de los documentos
* Presentación de distintos tipos de enlaces (xml, texto, pdfs) de manera más específica
* Mejora de estilos

Contribuye
----------

* [Abre una issue](https://github.com/miguelff/boe-transparente/issues/new) 
* [Soluciona alguna de las existentes](https://github.com/miguelff/boe-transparente/issues) 
* O simplemente, haz un fork del repo, experimenta, y comparte
