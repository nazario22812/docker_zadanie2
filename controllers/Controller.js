const express = require("express")
const router = express.Router()
const axios = require("axios") // Biblioteka do obsługi asynchronicznych zapytań HTTP

// Endpoint GET: Wyświetla początkowy widok formularza po wejściu na stronę
router.get("/", (req, res) => {
    res.render("main", { viewTitle: "Witaj w aplikacji" })
})


// Endpoint POST: Odbiera dane z formularza i pobiera pogodę (Realizacja punktu 1b)
router.post("/", async (req, res) => {
    try {
        // Pobranie wartości wybranych przez użytkownika na frontendzie
        const country = req.body.country; 
        const city = req.body.city;


        // Walidacja: upewnienie się, że użytkownik nie wysłał pustego zapytania
        if (!city || !country) {
            return res.render("main", { viewTitle: "Błąd", error: "Wybierz kraj i miasto!" });
        }
        // Zapytanie do zewnętrznego API OpenWeatherMap. 
        // Parametr units=metric gwarantuje, że temperatura wróci w stopniach Celsjusza.
        const response = await axios.get(`https://api.openweathermap.org/data/2.5/weather?q=${city},${country}&appid=2ef2675651a639cbe9f4edc00c9f0ac2&units=metric`);
        
        // Zapisanie odpowiedzi i przekazanie jej do widoku Handlebars ('weatherData')
        const weatherData = response.data;
        res.render("main", { viewTitle: "Pogoda", weather: weatherData });

    } catch (error) {
        // Zabezpieczenie na wypadek awarii API lub podania nieistniejącego miasta
        console.error("Błąd podczas pobierania danych pogodowych:", error.message);
        res.render("main", { viewTitle: "Błąd", error: "Nie można pobrać danych pogodowych." });
    }
})

module.exports = router;