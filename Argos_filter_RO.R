# Pregatirea setului de date Argos pentru filtrare

# Declaram directorul in care lucram. Acest script citeste datele din
# subfolderul *data* si va salva rezultatele in subfolderul *output*,
# astfel trebuie sa cream doua foldere numite output si data, sau sa
# modificam scriptul acolo unde este necesar

setwd("set your working directory")

# Activam pachetul R dplyr. Daca nu este disponibil trebuie descarcat cu comanda
# install.packages(dplyr). Tutorialul pentru acest pachet R este la adresa web
# https://dplyr.tidyverse.org/

library(dplyr)

# Se incarca fisierul cu date brute Argos (export csv din Argos CLS, cu datele de
# diagnostic). Vom lucra cu fisier date Argos PTT Geotrack 23G SOLAR PTT
# obtinut in cadrul proiectului PN-III-P2-2.1-PED-2016-056 finantat de UEFISCDI
# (http://ccmesi.ro/?page_id=47). Setul de date demonstrativ cuprinde
# 2681 observatii si 39 variabile din zona Saveni, IL (test static)

Argos_data <- read.csv(file = "data/argos_data.csv",
                       header = TRUE,
                       as.is = TRUE)

# Vizualizam elementele din setul de date Argos_data (tip variabila, nume
# variabila, date) cu functia glimpse care transpune tabelul

glimpse(Argos_data)

# Filtru date duplicate

# Dupa importul setului de date vom sterge datele duplicate. Date Argos exportate
# in format csv includ duplicate pentru fiecare localizare, constand in mesaje
# multiple pentru fiecare locatie obtinuta de 1 PTT. Cum mesajele pentru o locatie
# sunt identice cu exceptia marcii temporale Msg.Date vom pastra doar primul mesaj
# din fiecare serie. Consideram duplicate mesajele care au informatie identica
# pentru variabilele Platform.ID.No. (ID-platformei), Pass.dur...s. (durata
# receptiei),  Sat. (satelitul care  a generat localizarea), Loc..date (data
# localizarii). In acest fel excludem posibilitatea sa stergem gresit mesajele.
# Numele corecte ale variabilelor le identificam usor cu functia glimpse ca mai sus.

argos.dup <-
  distinct(Argos_data,
           Platform.ID.No.,
           Pass.dur...s.,
           Sat.,
           Loc..date,
           .keep_all = TRUE)

# Functia *distinct* a pastrat 521 localizarii din 2681 de mesaje initiale.

# Filtru date fara coordonate si data de localizare

# Din noul set de date *argos.dup* vom  elimina succesiv datele cu NA (lipsa date)
# in coloanele Loc..date, Longitude, Latitude. Acestea sunt localizari invalide.
# Utilizam succesiv functia filter reluand setul de date anterior.

argos.dup.1 <-   filter(argos.dup, !is.na(Loc..date))
argos.dup.2 <-   filter(argos.dup.1, !is.na(Longitude))
argos.dup.3 <-   filter(argos.dup.2, !is.na(Latitude))


# Setul de date final *argos.dup3* reprezinta un set de date prelucrat, gata
# pentru utilizare in analize.

# Stergem seturile de date intermediare si pastram doar setul final *argos.dup3*

rm("Argos_data", "argos.dup", "argos.dup.1", "argos.dup.2")

# Explorarea datelor

# Vom explora setul de date, de exemplu numaram localizarile per individ (PTT)

count(argos.dup.3, Platform.ID.No.)

# Reprezentam grafic numarul de localizari per animal (Platform.ID.No.).
# Pentru aceasta cream un tabel cu numarul de localizari cu functia table si
# apoi utilizam functia plot din pachetul de baza al R

counts <- table(argos.dup.3$Platform.ID.No.)

barplot(counts, main = "Numar de localizari per individ")


# Pentru o mai buna intelegere a datelor putem vizualiza localizarile cu ajutorul
# pachetelor mapview si sp. Atentie daca pachetele nu sunt disponibile atunci
# trebuie instalate cu functia install.packages().

library(sp)
library(mapview)

# Cream coordonate spatiale din Longitudine si latitudine (obiect spatial points).
# Pentru a nu avea erori vom declara un nou nume la setul de date prelucrat

argos_harta <- argos.dup.3

coordinates(argos_harta) <- ~ Longitude + Latitude

# Declaram proiectia ca WGS84 (epsg:4326)

proj4string(argos_harta) <- CRS("+init=epsg:4326")

# vizualizam harta cu functia mapview, cu culori diferite pentru fiecare individ.
# Atentie! harta este interactiva si are functii de zoom, selectare animal,
# schimbare de harta fundal


harta_Saveni <- mapview(argos_harta,
                        zcol = "Platform.ID.No.",
                        burst = TRUE)

harta_Saveni

# Hartile create au dimensiuni mari, astfel ca pentru reprezentari grafice
# a unor zone mari recomandam functia plot.
# Stergem seturile de date intermediare si pastram doar setul final *argos.dup3*

rm("argos_harta", "harta_Saveni", "counts")

# Salvam setul de date prelucrat argos.dup.3 sub numele de argos_clean.csv

write.csv(argos.dup.3, file = "output/argos_clean.csv")


# Filtru calitate localizari Argos (Loc..quality).

# Filtrul elimina localizarile considerate ca avand eroare prea mare
# (de exemplu LC0, LCA si LCB care nu au eroare estimata).

argos.dup.3$Loc..quality <- factor(argos.dup.3$Loc..quality,
                                   levels = c("3", "2", "1", "0", "A", "B"))


# Construim un tabel cu numarul de localizari dupa clasa de eroare si
# vizualizam sub forma de diagrama barplot


count_LC <- table(argos.dup.3$Loc..quality)

barplot(count_LC, main = "Numarul de localizari dupa clasa de eroare")


## Cream un set de date filtrat cu clasele de eroare 3, 2 si 1


argos.LC321 <-
  filter(argos.dup.3,
         Loc..quality == 3 | Loc..quality == 2 | Loc..quality == 1)

# Vizualizam harta cu datele filtrate si date nefiltrate

argos_harta <- argos.dup.3

coordinates(argos_harta) <- ~ Longitude + Latitude
proj4string(argos_harta) <- "+init=epsg:4326"
harta1 <- mapview(argos_harta, zcol = "Loc..quality", burst = TRUE)
harta1


argos_hartaLC321 <- argos.LC321

coordinates(argos_hartaLC321) <- ~ Longitude + Latitude
proj4string(argos_hartaLC321) <- "+init=epsg:4326"
harta2 <-
  mapview(
    argos_hartaLC321,
    zcol = "Loc..quality",
    burst = TRUE,
    layer.name = "date prelucrate LC321"
  )
harta2

# si le putem vizualizam una langa alta

latticeView(harta1, harta2, sync.cursor = TRUE)


# acceasi reprezentare grafica cu functia plot si libraria rgdal
# genereaza un grafic e marime mai mica

library(sp)

coord.nefiltrate = SpatialPoints(
  cbind(argos_harta$Longitude, argos_harta$Latitude),
  proj4string = CRS("+proj=longlat")
)

coord.filtru.231 = SpatialPoints(
  cbind(argos_hartaLC321$Longitude, argos_hartaLC321$Latitude),
  proj4string = CRS("+proj=longlat")
)

par(mfrow = c(1, 2))

plot(coord.nefiltrate,
     axes = TRUE,
     main = "Localizari Saveni nefiltrate",
     cex.axis = 0.95)
plot(
  coord.filtru.231,
  axes = TRUE,
  main = "Localizari Saveni filtrate",
  col = "red",
  cex.axis = 0.95
)

# Stergem setarile functiei par() din RStudio

dev.off()

# Daca nu dorim sa le fitram fizic putem utiliza sp si mapview sa exploram setul
# de date, folosind variabila Loc..quality pentru legenda (debifam in viewer
# locatiile # care au erori...de exemplu in setul nostru de date erorile
# provim din LC 0 si LC B, dar obsevam si ca aplicand filtrul distructiv
# vom elimina multe locatii valoaroase)
# pentru aceasta vizualizam harta mapview cu toate locatiile (harta1)

harta1

# In final salvam versiunea de date filtrate care raspunde cerintelor noastre, in
# cazul nostrul setul de date cu LC3, LC2 si LC1

write.csv(argos.LC321, file = "output/argos_LC321.csv")


# Filtru de viteza

# stergem toate seturile de date si detasam pachetele incarcate pana acum

rm(list = ls())

detach("package:dplyr")
detach("package:sp")
detach("package:mapview")

# Incarcam pachetele SDL filter si dplyr, in ordinea aceasta (au functii cu
# nume asemanatoare care se suprascriu). Daca apar erori la unele functii
# de mai jos, atunci trebuie sa detasam pachetele (detach) si sa le 
# reincaram

library(SDLfilter)
library(dplyr)

# Incarcam fisierul ce contine date prelucrate dar nefiltrate cu filtru LC
# (argos_clean.cvs). Daca dorim sa lucram cu cele filtrare incarcam fisierul
# corespunzator

Argos_clean <- read.csv(file = "output/argos_clean.csv",
                        header = TRUE,
                        as.is = TRUE)


# Redenumim coloanele pentru a putea lucra cu functiile SDL filter
# (vezi documentatie SDLfilter)

argos.renamed <-
  rename(
    Argos_clean,
    id = Platform.ID.No.,
    lon = Longitude,
    lat = Latitude,
    DateTime1 = Loc..date,
    qi = Msg
  )

# Vizualizam tabelul pentru a fi siguri ca s-a procedat corect

glimpse(argos.renamed)

# Transformam variabila cu marca temporala (Datetime1, fost Loc..date) 
# in format data-time POSIXct. Atentie, sistemtul Windows afiseaza campurile
# cu date/timp in functie de setarile computerului, astfel ca inainte de 
# transformare trebuie sa vedem care este formatul

glimpse(argos.renamed$DateTime1)

# in cazul nostru formatul este "20-08-2017 07:07:01", unde 20 este ziua, 08
# este luna, 2017 este anul, apoi succesiune cu ora, minutul, secunda. Formatul
# POSIXct este "%d-%m-%Y %H:%M:%OS", unde d este ziua, m este luna din 2 cifre,
# Y este anul din 4 cifre, despartite de linie (-), H este ora din 2 cifre, M
# este minutul din 2 cifre si OS este secunda din 2 cifre, despartite de :.
# Toate au in fata semnul %. Mai multe detalii despre formatul data/timp in
# R aici https://www.stat.berkeley.edu/~s133/dates.html


# Transformam data din format chr (caracter) in format dttm (date time)si o
# copiem intr-un camp nou DateTime

argos.renamed$DateTime <-
  as.POSIXct(paste(argos.renamed$DateTime1),
             format = "%d-%m-%Y %H:%M:%OS")

# Citim campul nou creat. Trebuie sa apara POSIXct[1:520], format:
# "2017-08-20 07:07:01" . Daca avem NA atunci nu este corect si trebuie
# sa reluam pasii prin fixarea unui format data adecvat

glimpse(argos.renamed$DateTime)


# Dupa fixarea datei putem lucra cu filtrele de viteza, de
# exemplu putem estima viteza maxima pentru deplasare in circuit.

maxvlp <- est.maxvlp(argos.renamed)

# Estiman viteza maxima pentru punctele cu mai mult de n mesaje PTT.
# Pentru aceasta ordonam clasele de eroare de la mare la mica si
# apoi reprezentam grafic clasa de eroare vs numarul de mesaje per
# localizare

argos.renamed$Loc..quality <- factor(argos.renamed$Loc..quality,
                                     levels = c("3", "2", "1", "0", "A", "B"))

plot(argos.renamed$Loc..quality, argos.renamed$qi)

# din grafic rezulta ca punctele cu qi 7 reprezinta mediana clasei
# de eroare 3 (cea mai mica), deci localizarile din mai mult de 7 mesaje
# sunt cele mai plauzibile

vmax4 <- est.vmax(argos.renamed, qi = 7, prob = 0.99)

# in acest moment avem toate elementele pentru a aplica filtrul de viteza.
# Viteza maxima plauzibila este de 17.7 km/h deci 18. Metoda 1 reprezinta
# modul in care se calculeaza daca punctele depasesc vmax. 1 punctul A si
# punctul subsecvent B, 2 concomitent intre A' A si A si B. Metoda 1 este
# mai radicala, metoda 2 elimina mai putine puncte. Recomandam metoda 1

argos.speed4 <- ddfilter.speed(argos.renamed, vmax = 18, method = 1)

# Putem aplica filtrul de viteza si prin includerea alaturi de vmax, maxvlp
# numar de mesaje, unghiul intern intre doua localizari (unghiul de intoarcere).
# Fiind un filtru complex este util pentru explorare. Necesita cunoasterea
# foarte buna a speciei cu care lucram.

argos.speed.complex <-
  ddfilter(
    argos.renamed,
    vmax = 18,
    maxvlp = 1.5,
    qi = 4,
    ia = 10,
    method = 1
  )

# Putem vizualiza datele filtrate si nefiltrate pentru a vedea efectul acestor
# filtre

library(mapview)
library(sp)

argos_brut <- Argos_clean

coordinates(argos_brut) <- ~ Longitude + Latitude
proj4string(argos_brut) <- "+init=epsg:4326"
harta.brut <-
  mapview(argos_brut, zcol = "Platform.ID.No.", burst = TRUE)
harta.brut

coordinates(argos.speed4) <- ~ lon + lat
proj4string(argos.speed4) <- "+init=epsg:4326"
harta.speed <- mapview(argos.speed4, zcol = "id", burst = TRUE)
harta.speed


latticeView(harta.brut, harta.speed, sync.cursor = TRUE)

# salvam fisierul cu datele filtrate exclusiv dupa vmax = 18, metoda 1

write.csv(argos.speed4, file = "output/argos.speed4.csv")

# Filtrul dezolvat de Freitas et al. 2008 presupune filtrarea functie de
# viteza maxima intre doua locatii, vmax = viteaza maxima plauzibila in m/s)

library(argosfilter)

date.filtrate <- vmask(
  argos.renamed$lat,
  argos.renamed$lon,
  argos.renamed$DateTime,
  vmax = 5)

date.filtrate

# atasam infomatia obtinuta setului de date argos.renamed si numaram
# locatiile filtrate pentru a vedea efectele filtrului

argos.renamed<-
  mutate(argos.renamed, date.filtrate = date.filtrate)

count(argos.renamed, date.filtrate)

# in final vom reprezenta grafic locatiile dupa tip (removed/not removed)

library(mapview)
library(sp)

argos.filtruv <- argos.renamed

coordinates(argos.filtruv) <- ~ lon + lat
proj4string(argos.filtruv ) <- "+init=epsg:4326"
harta.fitru.viteza <-
  mapview(argos.filtruv , zcol = "date.filtrate", burst = TRUE)

harta.fitru.viteza

# Daca filtrarea raspunde necesitatilor atunci vom salva fisierul
# pastrand doar locatiile marcate ca true si end location

argos_filtrate_5ms <- filter(argos.renamed,
              date.filtrate == "true" | date.filtrate == "end_location")

glimpse(argos_filtrate_5ms)

write.csv(argos_filtrate_5m, file = "output/argos.speed.5ms.csv")

# Stergem seturile de date din RStudio si detasam pachetele R 

rm(list = ls())

detach("package:dplyr")
detach("package:sp")
detach("package:mapview")
detach("package:SDLfilter")
detach("package:argosfilter")

# Pregatirea datelor pentru filtrul Douglas-Argos.


# Filtrul Douglas-Argos este disponibil numai in platforma Movebank
# Experienta noastra a demonstrat ca varianta DAR a Douglas-Argos
# este un filtru robust pentru conditiile din Romania

# Incarcam datele brute fara duplicate, create anterior (fisier argos_clean.csv).
# Daca nu le avem create atunci vom curata datele  pana la linia 122 din script 
# (stergerea duplicatelor, stergerea inregistrarilor cu NA pentru marca temporala,
# longitudine, latitudine)


Argos_clean <- read.csv(file = "output/argos_clean.csv",
                       header = TRUE,
                       as.is = TRUE)

library(dplyr)

# Redenumim variabilele necesare filtrului Douglas-Argos, numele variabilei
# il alfam cu functia glimpse

glimpse(Argos_clean)


argos.movebank <-
  rename(
    Argos_clean,
    PTT = Platform.ID.No.,
    lat1 = Lat..sol..1,
    lon1 = Long..1,
    lat2 = Lat..sol..2,
    lon2 = Long..2,
    DateTime = Loc..date,
    LC = Loc..quality,
    IQ = Loc..idx,
    Nbmes = Msg,
    Nbmes.120 = X....120.DB,
    Best.level = Best.level,
    Passduration = Pass.dur...s.,
    NOPC = Nopc,
    Calcul.Freq = Delta.freq.,
    Altitude = Altitude
  )

# salvam un fisier txt pentru upload in Movebank. Fisierul il vom incarca in Movebank,
# Edit studies, Upload data, add Processed Argos data (csv). Inainte de incarcare
# trebuie sa facem cont si sa activam un studiu...detalii aici ... 
# https://www.movebank.org/node/11. De asemenea detalii despre cum rulam filtrul
# gasim aici https://www.movebank.org/node/38 si in articolul open source
# https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/j.2041-210X.2012.00245.x


write.table(argos.movebank, file = "output/argos.movebank.txt", sep = "\t",
            row.names = FALSE, col.names = TRUE)
