# `source/data/` - mapa kategorii i kolorow

W `source/data/` kazdy provider dostaje `category`, ktora jest uzywana jako kolor
w gauge oraz jako semantyczne grupowanie danych. Cel jest prosty: jeden kolor ma
oznaczac jeden typ informacji, a nie przypadkowa mieszanke metryk.

## Zasady

- `category` opisuje sens danych, nie tylko ich wyglad.
- `gauge` bierze kolor bezposrednio z `Data.Base.category`.
- Metryki pogodowe maja osobna kategorie, bo nie pasuja ani do ruchu, ani do
  fizjologii, ani do zasobow systemowych.
- `uv` zostaje w energii, bo opisuje ekspozycje na promieniowanie sloneczne.

## Mapa kolorow

- `CATEGORY_MOVEMENT` = zielony
  - krokow
  - dystans
  - pushes
  - active minutes

- `CATEGORY_PHYSIOLOGICAL` = czerwony
  - heart rate
  - respiration rate
  - saturation
  - move bar
  - VO2 max

- `CATEGORY_RECOVERY` = cyjan
  - body battery
  - recovery time

- `CATEGORY_SYSTEM` = niebieski
  - battery
  - memory

- `CATEGORY_VERTICAL` = magenta
  - elevation
  - floors climbed / descended
  - meters climbed / descended

- `CATEGORY_ENERGY` = zolty
  - calories
  - stress
  - solar intensity
  - uv

- `CATEGORY_WEATHER` = accent / pomarancz
  - rain
  - wind
  - temperature
  - pressure

## Dlaczego tak

- `rain`, `wind`, `temperature` i `pressure` to dane srodowiskowe, wiec
  najlepiej wygladaja jako osobna grupa pogodowa.
- `uv` jest blizej ekspozycji slonecznej i energii niz zwyklej pogody.
- `move` zostaje czerwone, bo Move Bar jest bardziej wskaznikiem obciazenia
  niz czystej aktywnosci ruchowej.

## Przy dodawaniu nowego providera

1. Najpierw wybierz kategorie wedlug sensu danych.
1. Potem sprawdz, czy kolor nie dubluje juz istniejacej grupy znaczeniowej.
1. Jesli metryka nie pasuje do zadnej z istniejacych grup, dodaj nowa tylko wtedy,
   gdy bedzie uzyta wiecej niz raz.
