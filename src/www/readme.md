# DRAFT
## A simple Web App based remote control for the ha-bridge
* Place the files `remote.htm` and `manifest.json` on the same web server you have ha-bridge running through.
   * The files will usually go in directory: `/var/www/html`.
   
   ```
   cd /var/www/html
   sudo wget "https://raw.githubusercontent.com/mhightower83/x10ctrl/master/src/www/remote.htm"
   sudo wget "https://raw.githubusercontent.com/mhightower83/x10ctrl/master/src/www/manifest.json"
   ```
* To use from the Chrome browser on a smart phone, access remote.htm on the server.
   * eg. `http://hapi/remote.htm`.
* Use the Chrome menu, the 3 verticle dots, select "Add to Home screen" and follow the prompts.
