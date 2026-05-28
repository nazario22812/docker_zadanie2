const express = require("express")
const path = require("path")
const handleBars = require("handlebars")
const exphbs = require("express-handlebars")
const {allowInsecurePrototypeAccess} = require("@handlebars/allow-prototype-access")
const controller = require("./controllers/Controller")
const app = express()
app.use(express.urlencoded(
    {
        extended: true
    }
))
// Middleware pozwalające na odczytywanie danych przesyłanych z formularzy (metoda POST)
app.use(express.urlencoded({
    extended: true
}))
// Konfiguracja silnika szablonów Handlebars oraz wskazanie folderu z widokami
app.set("views", path.join(__dirname, "views"))
app.engine(
    "hbs",
    exphbs.engine({
        handlebars: allowInsecurePrototypeAccess(handleBars),
        extname: "hbs",
        defaultLayout: "layout",
        layoutsDir: path.join(__dirname, "views/layouts"),
    })
)
app.set("view engine", "hbs")
// Podpięcie logiki routingu z zewnętrznego kontrolera
app.use("/", controller)
// Uruchomienie serwera aplikacji
app.listen(3000, () => {
    // Wymóg 1a z zadania: Wyrzucenie do logów informacji o starcie, autorze i porcie
    const data = new Date().toLocaleString("pl-PL")
    console.log(data)
    console.log('Autor: Nazarii Kravchenko')
    console.log("Serwer nasłuchuje na porcie 3000")
})