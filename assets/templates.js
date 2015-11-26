this["JST"] = this["JST"] || {};

this["JST"]["views/templates/accessibility-personalisation"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),label = locals_.label,selected = locals_.selected,uppercaseFirst = locals_.uppercaseFirst,t = locals_.t,accessibility_viewpoints = locals_.accessibility_viewpoints;
jade_mixins["renderMode"] = function(group, type, icon, activeViewpoints){
var block = (this && this.block), attributes = (this && this.attributes) || {};
label = "label-" + group + "-" + type
buf.push("<li" + (jade.attr("data-group", group, true, false)) + (jade.attr("data-type", type, true, false)) + (jade.cls([(activeViewpoints.indexOf(type) != -1 ? 'selected' : '')], [true])) + "><a href=\"#\" role=\"button\"" + (jade.attr("aria-pressed", selected, false, false)) + (jade.attr("aria-described-by", label, true, false)) + " tabindex=\"1\"><div class=\"icon\"><span" + (jade.cls(["icon-icon-" + (icon) + ""], [false])) + "></span></div><span" + (jade.attr("id", label, true, false)) + " class=\"text\">" + (null == (jade_interp = uppercaseFirst(t("personalisation." + type))) ? "" : jade_interp) + "</span></a></li>");
};
buf.push("<div class=\"section\"><h3>" + (jade.escape(null == (jade_interp = t('personalisation.hearing_and_sight')) ? "" : jade_interp)) + "</h3><ul class=\"personalisations\">");
jade_mixins["renderMode"]('senses', 'hearing_aid', 'hearing-aid', accessibility_viewpoints);
jade_mixins["renderMode"]('senses', 'visually_impaired', 'visually-impaired', accessibility_viewpoints);
jade_mixins["renderMode"]('senses', 'colour_blind', 'colour-blind', accessibility_viewpoints);
buf.push("</ul></div><div class=\"section\"><h3>" + (jade.escape(null == (jade_interp = t('personalisation.mobility')) ? "" : jade_interp)) + "</h3><ul class=\"personalisations\">");
jade_mixins["renderMode"]('mobility', 'wheelchair', 'wheelchair', accessibility_viewpoints);
jade_mixins["renderMode"]('mobility', 'reduced_mobility', 'reduced-mobility', accessibility_viewpoints);
jade_mixins["renderMode"]('mobility', 'rollator', 'rollator', accessibility_viewpoints);
jade_mixins["renderMode"]('mobility', 'stroller', 'stroller', accessibility_viewpoints);
buf.push("</ul></div>");;return buf.join("");
};

this["JST"]["views/templates/accessibility-viewpoint-oneline"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),profileSet = locals_.profileSet,profiles = locals_.profiles,t = locals_.t;
buf.push("<div class=\"row\"><div class=\"col-xs-9\">");
if ( profileSet)
{
// iterate profiles
;(function(){
  var $$obj = profiles;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var profile = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',profile['icon']], [null,false])) + "></span>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var profile = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',profile['icon']], [null,false])) + "></span>");
    }

  }
}).call(this);

// iterate profiles
;(function(){
  var $$obj = profiles;
  if ('number' == typeof $$obj.length) {

    for (var i = 0, $$l = $$obj.length; i < $$l; i++) {
      var profile = $$obj[i];

buf.push("<span class=\"profile\">" + (null == (jade_interp = ' ' + profile['text']) ? "" : jade_interp) + "</span>");
if ( i == profiles.length - 2)
{
buf.push(jade.escape(null == (jade_interp = t('general.and')) ? "" : jade_interp));
}
else if ( i != profiles.length - 1)
{
buf.push(", ");
}
else if ( i == profiles.length - 1)
{
buf.push(".");
}
    }

  } else {
    var $$l = 0;
    for (var i in $$obj) {
      $$l++;      var profile = $$obj[i];

buf.push("<span class=\"profile\">" + (null == (jade_interp = ' ' + profile['text']) ? "" : jade_interp) + "</span>");
if ( i == profiles.length - 2)
{
buf.push(jade.escape(null == (jade_interp = t('general.and')) ? "" : jade_interp));
}
else if ( i != profiles.length - 1)
{
buf.push(", ");
}
else if ( i == profiles.length - 1)
{
buf.push(".");
}
    }

  }
}).call(this);

}
else
{
buf.push("<p>" + (jade.escape(null == (jade_interp = t('accessibility.profile_not_set')) ? "" : jade_interp)) + "</p>");
}
buf.push("</div><div class=\"col-xs-3\"><a href=\"#\" class=\"set-accessibility-profile\">" + (jade.escape(null == (jade_interp = t('transit.route_settings.edit')) ? "" : jade_interp)) + "</a></div></div>");;return buf.join("");
};

this["JST"]["views/templates/accessibility-viewpoint-summary"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),profile_set = locals_.profile_set,t = locals_.t,profiles = locals_.profiles;
if ( profile_set)
{
buf.push("<span>" + (null == (jade_interp = t('accessibility.details_filtered_by_profile') + ': ') ? "" : jade_interp) + "</span>");
// iterate profiles
;(function(){
  var $$obj = profiles;
  if ('number' == typeof $$obj.length) {

    for (var i = 0, $$l = $$obj.length; i < $$l; i++) {
      var profile = $$obj[i];

buf.push("<span class=\"profile\">" + (null == (jade_interp = profile['text']) ? "" : jade_interp) + "</span>");
if ( i == profiles.length - 2)
{
buf.push(jade.escape(null == (jade_interp = t('general.and')) ? "" : jade_interp));
}
else if ( i != profiles.length - 1)
{
buf.push(", ");
}
else if ( i == profiles.length - 1)
{
buf.push(".");
}
    }

  } else {
    var $$l = 0;
    for (var i in $$obj) {
      $$l++;      var profile = $$obj[i];

buf.push("<span class=\"profile\">" + (null == (jade_interp = profile['text']) ? "" : jade_interp) + "</span>");
if ( i == profiles.length - 2)
{
buf.push(jade.escape(null == (jade_interp = t('general.and')) ? "" : jade_interp));
}
else if ( i != profiles.length - 1)
{
buf.push(", ");
}
else if ( i == profiles.length - 1)
{
buf.push(".");
}
    }

  }
}).call(this);

buf.push("<div>");
// iterate profiles
;(function(){
  var $$obj = profiles;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var profile = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',profile['icon']], [null,false])) + "></span>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var profile = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',profile['icon']], [null,false])) + "></span>");
    }

  }
}).call(this);

buf.push("<a href=\"#\" class=\"set-accessibility-profile\">" + (null == (jade_interp = ' ' + t('accessibility.modify_profile')) ? "" : jade_interp) + "</a></div>");
};return buf.join("");
};

this["JST"]["views/templates/context-menu-item"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),name = locals_.name;
buf.push("<a href=\"#!\" class=\"external-link\">" + (null == (jade_interp = name) ? "" : jade_interp) + "&nbsp;<span class=\"icon-icon-outbound-link\"></span></a>");;return buf.join("");
};

this["JST"]["views/templates/context-menu-wrapper"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div class=\"contents\"></div><div class=\"arrow right\"></div>");;return buf.join("");
};

this["JST"]["views/templates/description-of-service"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),lang = locals_.lang;
buf.push("<div class=\"modal-content about\"><div class=\"modal-header\"><div class=\"section\">");
if ( lang == 'fi')
{
buf.push("<h1>Palvelukartta (beta) <a href=\"#\" data-dismiss=\"modal\" class=\"icon icon-icon-close\"></a></h1>");
}
if ( lang == 'sv')
{
buf.push("<h1>Servicekartan (beta)<a href=\"#\" data-dismiss=\"modal\" class=\"icon icon-icon-close\"></a></h1>");
}
if ( lang == 'en')
{
buf.push("<h1>The Service Map (beta)<a href=\"#\" data-dismiss=\"modal\" class=\"icon icon-icon-close\"> </a></h1>");
}
buf.push("</div></div><div class=\"modal-body\"><div class=\"section\">");
if ( lang == 'fi')
{
buf.push("<h2><span class=\"icon icon-icon-info\"></span> Tietoa palvelusta</h2><p>Palvelukartta on avoin tiedotuskanava Helsingin, Espoon, Vantaan ja Kauniaisten kaupunkien toimipisteistä ja palveluista. Palvelukartta opastaa kuntalaisia löytämään aina ajantasaisimman tiedon kaupungin tarjoamista palveluista ja niiden esteettömyydestä. Kartan kautta on mahdollisuus antaa palautetta ja käydä avointa keskustelua suoraan toimipisteistä ja palveluista vastaavien kanssa.</p><p>Palvelukartan toimintoihin voit tutustua opastuskierroksella.</p><p>Tämä on Palvelukartan toisen version beta-aste. Kaikkia ensimmäisen Palvelukartan toiminnallisuuksia ei vielä ole ehditty toteuttaa tässä versiossa. Niiden käyttöä varten on edellinen Palvelukartta käytössä toistaiseksi.</p><p>Palvelukartta on myös <a target=\"_blank\" href=\"https://www.facebook.com/palvelukartta\" class=\"external-link\">Facebookissa.</a></p><p>Palvelu on toteutettu Helsingin kaupungin kaupunginkanslian <a target=\"_blank\" href=\"http://www.hel.fi/www/kanslia/fi/osastot-ja-yksikot/tietotekniikka/\" class=\"external-link\"></a> tietotekniikka- ja viestintäosaston tietotekniikkayksikössä.</p><h2><span class=\"icon icon-icon-feedback\"></span> Palaute</h2><p>Kiitämme kaikesta palautteesta, jotta voimme kehittää Palvelukarttaa yhä paremmaksi.</p><p>Lähetä palautetta Palvelukartasta</p><p>Palvelukartan kautta voit lähettää palautetta myös yksittäisille toimipisteille. Hae haluamasi toimipiste kartalle, niin löydät palautelomakkeen toimipisteen tiedoista.</p><h2>© Tiedot ja tekijänoikeudet</h2><p>Palvelukartta on rakennettu mahdollisimman täydellisesti avointa dataa ja avointa lähdekoodia käyttäen.</p><p>Kartan lähdekoodi löytyy <a target=\"_blank\" href=\"https://github.com/City-of-Helsinki/servicemap/\" class=\"external-link\">GitHubista</a> ja sen kehittämiseen rohkaistaan.</p><p>Palveluiden ja palvelupisteiden tiedot ovat avointa dataa ja käytettävissä <a target=\"_blank\" href=\"http://www.hel.fi/palvelukarttaws/rest/\" class=\"external-link\">REST-rajapinnan kautta.</a></p><p>Karttatiedot haetaan avoimesta <a target=\"_blank\" href=\"https://www.openstreetmap.org/\" class=\"external-link\">OpenStreetMapista</a> ja niiden tekijänoikeus kuuluu <a target=\"_blank\" href=\"https://www.openstreetmap.org/copyright\" class=\"external-link\">OpenStreetMapin tekijöille.</a></p><p>Reittitiedot tuodaan palveluumme ulkopuolisista tietolähteistä. Emme voi valitettavasti taata tietojen oikeellisuutta.</p><p>Poikkeuksena vapaaseen käyttöön veistosten ja julkisen taiteen pisteiden valokuvat ovat tekijänoikeussuojattuja, eikä niitä voi käyttää kaupallisiin tarkoituksiin.</p><p>Rekisteriselosteet löytyvät kootusti <a target=\"_blank\" href=\"http://www.hel.fi/www/helsinki/fi/kaupunki-ja-hallinto/hallinto/organisaatio/rekisteriselosteet\" class=\"external-link\">hel.fi-portaalista.</a> Katso kohdat Kaupunginkanslia: Toimipisterekisterin keskitetty tietovarasto ja Helsingin kaupungin palautejärjestelmä.</p>");
}
if ( lang == 'sv')
{
buf.push("<h2><span class=\"icon icon-icon-info\"></span> Information om tjänsten</h2><p>Servicekartan är en öppen informationskanal om Helsingfors, Esbo, Vanda och Grankulla städers verksamhetsställen och tjänster. Servicekartan hjälper kommuninvånare att alltid hitta de senaste uppgifterna om de tjänster som staden erbjuder och om tjänsternas tillgänglighet. Det är möjligt att ge respons via kartan och föra en öppen diskussion direkt med de ansvariga för olika verksamhetsställen och tjänster.</p><p>Du kan bekanta dig med servicekartans funktioner på en guidad presentationsrunda.</p><p>Det här är betaversionen av Servicekartans andra version. I den här versionen har det ännu inte varit möjligt att inkludera alla funktioner som ingick i den första Servicekartan. Den tidigare Servicekartan finns tills vidare tillgänglig med tanke på användningen av dessa.</p><p>Servicekartan finns också på <a target=\"_blank\" href=\"https://www.facebook.com/palvelukartta\" class=\"external-link\">Facebook.</a></p><p>Tjänsten har tagits fram på IT- och kommunikationsavdelningens \nIT-enhet vid Helsingfors stadskansli.</p><h2><span class=\"icon icon-icon-feedback\"></span> Respons</h2><p>Vi är tacksamma för all respons, så att vi kan utveckla Servicekartan och göra den allt bättre.</p><p>Skicka respons om Servicekartan</p><p>Via Servicekartan kan du också skicka respons till enskilda verksamhetsställen. Sök verksamhetsstället på kartan, så hittar du en responsblankett bland uppgifterna om verksamhetsstället.</p><h2>© Information och upphovsrätt</h2><p>Servicekartan har byggts så långt som möjligt med hjälp av öppna data och öppen källkod.</p><p>Kartans källkod finns på GitHub och vi uppmuntrar användare att utveckla den.</p><p>Tjänsternas och verksamhetsställenas uppgifter är öppna data och kan användas via REST-gränssnittet.</p><p>Kartuppgifterna hämtas från öppna OpenStreetMaps och uppgifternas upphovsrätt ägs av upphovsmännen bakom OpenStreetMaps.</p><p>Informationen om färdvägar hämtas till vår tjänst från externa källor. Tyvärr kan vi inte garantera att uppgifterna är korrekta.</p><p>Undantag i fråga om fri användning är fotografier av skulpturer och av platser med offentlig konst, som skyddas av upphovsrätten och som inte får användas för kommersiella syften.</p><p>Registerbeskrivningarna finns samlade på portalen <a target=\"_blank\" href=\"http://www.hel.fi/static/helsinki/rekisteriselosteet/kanslia/TPR_%20Rekisteriseloste_SV.rtf\" class=\"external-link\">hel.fi.</a> Se punkterna Stadskansliet: Register över verksamhetsställen och Helsingfors stads responssystem.</p>");
}
if ( lang == 'en')
{
buf.push("<h2><span class=\"icon icon-icon-info\"></span> Information about the service</h2><p>The Service Map is an open information channel on the service points and services offered by the cities of Helsinki, Espoo, Vantaa and Kauniainen. The Service Map helps the inhabitants of the municipality find current information on services offered by the city, as well as on the accessibility of the services. Using the Map, it is possible to provide feedback and engage in open conversations directly with the people in charge at the services and the service points.</p><p>You can acquaint yourself with the functions of the Service Map through a guided tour. </p><p>This is the beta version of the second Service Map. All functions available in the first edition of the Service Map have not yet been implemented in this edition. The previous Service Map is available for the use of those functions until further notice.</p><p>The Service Map is also on <a target=\"_blank\" href=\"https://www.facebook.com/palvelukartta\" class=\"external-link\">Facebook.</a></p><p>The service was built at the <a target=\"_blank\" href=\"http://www.hel.fi/www/kanslia/fi/osastot-ja-yksikot/tietotekniikka/\" class=\"external-link Information\">Technology unit</a> of Information Technology and Communications at the City of Helsinki Executive Office.</p><h2><span class=\"icon icon-icon-feedback\"></span>Feedback</h2><p>We appreciate all feedback, which allows us to improve the Service Map and make it even better.</p><p>Provide feedback on the Service Map</p><p>You can also provide feedback to particular service points through the Service Map. Search the service point on the map, the feedback form can be found among the service point information.</p><h2><span class=\"icon icon-icon-copyright\"></span> Information and copyrights</h2><p>The Service Map was built using as much open data and open source code as possible.</p><p>The source code of the map is available on <a target=\"_blank\" href=\"https://github.com/City-of-Helsinki/servicemap/\" class=\"external-link\">GitHub</a> and we encourage users to develop it.</p><p>The information on services and service points are open data and usable through the <a target=\"_blank\" href=\"http://www.hel.fi/palvelukarttaws/rest/\" class=\"external-link\">REST interface.</a></p><p>The map data comes from the open service <a target=\"_blank\" href=\"https://www.openstreetmap.org/\" class=\"external-link\">OpenStreetMap</a> and the copyright of the data belongs to the <a target=\"_blank\" href=\"https://www.openstreetmap.org/copyright\" class=\"external-link\">makers of OpenStreetMap.</a></p><p>The route information is brought to our service from external sources. Unfortunately we cannot guarantee that the information is correct.</p><p>An exception to the free-to-use principle are photographs of sculptures and public art points, which are protected by copyright and cannot be used for commercial purposes.</p><p>The file descriptions are collected to the <a target=\"_blank\" href=\"http://www.hel.fi/www/helsinki/fi/kaupunki-ja-hallinto/hallinto/organisaatio/rekisteriselosteet\" class=\"external-link\">hel.fi portal</a> (available only in Finnish and partly in Swedish).\nCheck the sections Kaupunginkanslia: Toimipisterekisterin keskitetty tietovarasto and Helsingin kaupungin palautejärjestelmä.</p>");
}
buf.push("</div></div></div>");;return buf.join("");
};

this["JST"]["views/templates/details"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),tAttr = locals_.tAttr,phoneI18n = locals_.phoneI18n,embedded_mode = locals_.embedded_mode,back_to = locals_.back_to,name = locals_.name,picture_url = locals_.picture_url,t = locals_.t,picture_caption = locals_.picture_caption,provider = locals_.provider,department = locals_.department,street_address = locals_.street_address,address_zip = locals_.address_zip,municipality = locals_.municipality,phone = locals_.phone,www_url = locals_.www_url,highlights = locals_.highlights,description_ingress = locals_.description_ingress,description_body = locals_.description_body,opening_hours = locals_.opening_hours,links = locals_.links,organization = locals_.organization,status_class = locals_.status_class;
jade_mixins["renderConnection"] = function(conn){
var block = (this && this.block), attributes = (this && this.attributes) || {};
if ( tAttr(conn.www_url))
{
buf.push("<a" + (jade.attr("href", "" + (tAttr(conn.www_url)) + "", true, false)) + " target=\"_blank\" class=\"external-link\">" + (jade.escape(null == (jade_interp = tAttr(conn.name) + ' ') ? "" : jade_interp)) + "<span class=\"icon-icon-outbound-link\"></span></a>");
}
else
{
buf.push(jade.escape(null == (jade_interp = tAttr(conn.name)) ? "" : jade_interp));
if ( conn.phone)
{
buf.push(", <span itemprop=\"telephone\"><a" + (jade.attr("href", "tel:" + (phoneI18n(conn.phone)) + "", true, false)) + ">" + (jade.escape(null == (jade_interp = conn.phone) ? "" : jade_interp)) + "</a></span>");
}
}
};
buf.push("<div class=\"header\">");
if (!( embedded_mode))
{
if ( back_to)
{
buf.push("<a href=\"#\" role=\"button\" tabindex=\"0\" class=\"back-button vertically-aligned\"><span class=\"icon-icon-back-bold\"></span><span>" + (jade.escape(null == (jade_interp = back_to) ? "" : jade_interp)) + "</span></a>");
}
}
buf.push("<div class=\"mobile-header\"><div class=\"header-content\"><canvas id=\"details-marker-canvas-mobile\" width=\"30\" height=\"30\"></canvas><span class=\"icon-icon-close\"></span><h2><span>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</span></h2></div></div></div><div class=\"content limit-max-height\"><div class=\"map-active-area\"></div>");
if ( picture_url)
{
buf.push("<div class=\"image-wrapper\"><img" + (jade.attr("src", "" + (picture_url) + "", true, false)) + (jade.attr("alt", "" + (t('sidebar.picture_of')) + " " + (name) + "", true, false)) + " class=\"details-image\"/>");
if ( picture_caption)
{
buf.push("<div class=\"details-image-caption\">" + (jade.escape(null == (jade_interp = tAttr(picture_caption)) ? "" : jade_interp)) + "</div>");
}
buf.push("</div>");
}
buf.push("<div class=\"section main-info\"><div class=\"header\"><canvas id=\"details-marker-canvas\" width=\"30\" height=\"30\"></canvas><span class=\"icon-icon-close\"></span><h2><span>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</span></h2></div><div id=\"main-info-details\" class=\"section-content\"><div class=\"departments\">" + (jade.escape(null == (jade_interp = provider) ? "" : jade_interp)));
if ( provider && tAttr(department.name))
{
buf.push(": &nbsp;");
}
buf.push((jade.escape(null == (jade_interp = tAttr(department.name)) ? "" : jade_interp)) + "</div><div class=\"address\"><address>");
if ( street_address)
{
buf.push(jade.escape(null == (jade_interp = street_address) ? "" : jade_interp));
if ( address_zip || municipality)
{
buf.push(", &nbsp;");
}
}
if ( address_zip)
{
buf.push(jade.escape(null == (jade_interp = address_zip) ? "" : jade_interp));
}
if ( municipality)
{
if ( address_zip)
{
buf.push(" ");
}
buf.push(jade.escape(null == (jade_interp = tAttr(municipality.name)) ? "" : jade_interp));
}
buf.push("</address></div>");
if ( phone || tAttr(www_url))
{
buf.push("<div class=\"contact-info\">");
if ( phone)
{
buf.push("<span itemprop=\"telephone\"><a" + (jade.attr("href", "tel:" + (phoneI18n(phone)) + "", true, false)) + " class=\"external-link\">" + (jade.escape(null == (jade_interp = phone) ? "" : jade_interp)) + "</a></span>");
}
if ( phone && tAttr(www_url))
{
buf.push("&nbsp; | &nbsp;");
}
if ( tAttr(www_url))
{
buf.push("<a" + (jade.attr("href", "" + (tAttr(www_url)) + "", true, false)) + " target=\"_blank\" class=\"external-link\">" + (jade.escape(null == (jade_interp = t('sidebar.further_info') + ' ') ? "" : jade_interp)) + "<span class=\"icon-icon-outbound-link\"></span></a>");
}
buf.push("</div>");
}
if ( highlights)
{
buf.push("<div class=\"highlights\"><ul class=\"list-unstyled\">");
// iterate highlights
;(function(){
  var $$obj = highlights;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var conn = $$obj[$index];

buf.push("<li>");
jade_mixins["renderConnection"](conn);
buf.push("</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var conn = $$obj[$index];

buf.push("<li>");
jade_mixins["renderConnection"](conn);
buf.push("</li>");
    }

  }
}).call(this);

buf.push("</ul></div>");
}
buf.push("<div class=\"description\">");
if ( description_ingress)
{
buf.push("<span class=\"ingress\">" + (null == (jade_interp = description_ingress) ? "" : jade_interp) + "</span>");
}
if ( description_body)
{
buf.push(" <a href=\"#\" class=\"blue-link body-expander\">" + (jade.escape(null == (jade_interp = t('sidebar.show_more')) ? "" : jade_interp)) + "</a><span class=\"body\"> " + (null == (jade_interp = description_body) ? "" : jade_interp) + "</span>");
}
buf.push("</div>");
if ( opening_hours)
{
buf.push("<div class=\"opening-hours\"><strong>" + (jade.escape(null == (jade_interp = t('sidebar.hours')) ? "" : jade_interp)) + "</strong>");
// iterate opening_hours
;(function(){
  var $$obj = opening_hours;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var hours = $$obj[$index];

if ( hours.url)
{
buf.push("<a" + (jade.attr("href", hours.url, true, false)) + " class=\"external-link\">" + (jade.escape(null == (jade_interp = hours.content) ? "" : jade_interp)) + "&nbsp;<span class=\"icon-icon-outbound-link\"></span></a>");
}
else
{
buf.push("<p>" + (jade.escape(null == (jade_interp = hours.content) ? "" : jade_interp)) + "</p>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var hours = $$obj[$index];

if ( hours.url)
{
buf.push("<a" + (jade.attr("href", hours.url, true, false)) + " class=\"external-link\">" + (jade.escape(null == (jade_interp = hours.content) ? "" : jade_interp)) + "&nbsp;<span class=\"icon-icon-outbound-link\"></span></a>");
}
else
{
buf.push("<p>" + (jade.escape(null == (jade_interp = hours.content) ? "" : jade_interp)) + "</p>");
}
    }

  }
}).call(this);

buf.push("</div>");
}
buf.push("</div></div><div class=\"section route-section\"></div><div class=\"section accessibility-section\"></div><div class=\"section events-section hidden\"><a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#events-details\" class=\"collapser collapsed\"><h3><span class=\"icon-icon-events\">&nbsp;</span>" + (jade.escape(null == (jade_interp = t('sidebar.events')) ? "" : jade_interp)) + "</h3><span class=\"short-text\"></span></a><div id=\"events-details\" class=\"section-content collapse\"><div class=\"event-list\"></div><a href=\"#\" class=\"show-more-events\"><span>" + (jade.escape(null == (jade_interp = t('sidebar.show_more_events')) ? "" : jade_interp)) + "</span></a></div></div>");
if ( links && links.length)
{
buf.push("<div class=\"section\"><a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#web-services-details\" class=\"collapser collapsed\"><h3><span class=\"icon-icon-web-services\">&nbsp;</span>" + (jade.escape(null == (jade_interp = t('sidebar.web_services')) ? "" : jade_interp)) + "</h3><span class=\"short-text\">" + (jade.escape(null == (jade_interp = t('sidebar.service_count', {count: links.length})) ? "" : jade_interp)) + "</span></a><div id=\"web-services-details\" class=\"section-content collapse\"><ul>");
// iterate links
;(function(){
  var $$obj = links;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var conn = $$obj[$index];

buf.push("<li>");
jade_mixins["renderConnection"](conn);
buf.push("</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var conn = $$obj[$index];

buf.push("<li>");
jade_mixins["renderConnection"](conn);
buf.push("</li>");
    }

  }
}).call(this);

buf.push("</ul></div></div>");
}
if ( organization == 91)
{
buf.push("<div class=\"section feedback-section\"><a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#feedback-details\" class=\"collapser collapsed\"><h3><span class=\"icon-icon-feedback\">&nbsp;</span>" + (jade.escape(null == (jade_interp = t('sidebar.feedback')) ? "" : jade_interp)) + "</h3><span class=\"short-text\"></span></a><div id=\"feedback-details\" class=\"section-content collapse\"><a href=\"#\"" + (jade.cls(['send-feedback','blue-link',status_class], [null,null,false])) + ">" + (jade.escape(null == (jade_interp = t('feedback.send_feedback', {receiver: name})) ? "" : jade_interp)) + "</a><h4 class=\"feedback-count\"></h4><div class=\"feedback-list\"></div><!-- a.show-more-feedback(href=\"#\")--><!--   span= t('feedback.show_more_feedback')--></div></div>");
}
buf.push("</div>");;return buf.join("");
};

this["JST"]["views/templates/disclaimers-overlay"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,copyrightLink = locals_.copyrightLink,copyright = locals_.copyright;
buf.push("<a id=\"about-the-service\" href=\"#\" class=\"force\"><span class=\"icon icon-icon-info\">" + (jade.escape(null == (jade_interp = t('disclaimer.info')) ? "" : jade_interp)) + "</span></a>&nbsp;<a" + (jade.attr("id", copyrightLink ? "map-copyright" : "map-copyright-nolink", true, false)) + " target=\"_blank\"" + (jade.attr("href", copyrightLink ? copyrightLink : "#", false, false)) + " class=\"force\"><span class=\"icon icon-icon-copyright\">" + (jade.escape(null == (jade_interp = copyright) ? "" : jade_interp)) + "</span></a>");;return buf.join("");
};

this["JST"]["views/templates/division-list-item"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),selected = locals_.selected,uppercaseFirst = locals_.uppercaseFirst,t = locals_.t,type = locals_.type,name = locals_.name;
buf.push("<a href=\"#\"" + (jade.cls(['division',selected ? 'selected': ''], [null,true])) + "><div" + (jade.cls(['district',selected ? 'selected': ''], [null,true])) + "><div class=\"district-type\">" + (jade.escape(null == (jade_interp = uppercaseFirst(t('district.' + type))) ? "" : jade_interp)) + "</div>");
if ( name)
{
buf.push("<div class=\"title\">" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</div>");
}
buf.push("</div></a>");;return buf.join("");
};

this["JST"]["views/templates/embedded-title-bar"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),cutpoint = locals_.cutpoint,divisions = locals_.divisions,tAttr = locals_.tAttr,pad = locals_.pad,t = locals_.t;
buf.push("<div class=\"panel-heading\"><h5 data-toggle=\"collapse\" href=\"#filter-details\" class=\"collapser collapsed\">");
cutpoint = divisions.length - 2
if ( divisions.length > 2)
{
// iterate divisions.slice(0, cutpoint)
;(function(){
  var $$obj = divisions.slice(0, cutpoint);
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var division = $$obj[$index];

buf.push(jade.escape(null == (jade_interp = tAttr(division) + ', ') ? "" : jade_interp));
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var division = $$obj[$index];

buf.push(jade.escape(null == (jade_interp = tAttr(division) + ', ') ? "" : jade_interp));
    }

  }
}).call(this);

}
if ( divisions.length > 1)
{
buf.push((jade.escape(null == (jade_interp = tAttr(divisions[cutpoint])) ? "" : jade_interp)) + (jade.escape(null == (jade_interp = pad(t('sidebar.and'))) ? "" : jade_interp)) + (jade.escape(null == (jade_interp = tAttr(divisions[cutpoint + 1])) ? "" : jade_interp)));
}
if ( divisions.length == 1)
{
buf.push(jade.escape(null == (jade_interp = tAttr(divisions[0])) ? "" : jade_interp));
}
buf.push(":" + (jade.escape(null == (jade_interp = pad(t('sidebar.all_services'))) ? "" : jade_interp)) + "</h5></div><div id=\"filter-details\" class=\"panel-collapse collapse\"><div class=\"panel-body\">" + (jade.escape(null == (jade_interp = t('sidebar.public_services')) ? "" : jade_interp)) + "<a href=\"#\" role=\"button\" tabindex=\"0\" class=\"show-button public\">" + (jade.escape(null == (jade_interp = t('sidebar.hide')) ? "" : jade_interp)) + "</a></div><div class=\"panel-body\">" + (jade.escape(null == (jade_interp = t('sidebar.private_services')) ? "" : jade_interp)) + "<a href=\"#\" role=\"button\" tabindex=\"0\" class=\"show-button private\">" + (jade.escape(null == (jade_interp = t('sidebar.hide')) ? "" : jade_interp)) + "</a></div></div>");;return buf.join("");
};

this["JST"]["views/templates/embedded-title"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),href = locals_.href,staticPath = locals_.staticPath,lang = locals_.lang,t = locals_.t;
buf.push("<div class=\"bottom-logo\"><a" + (jade.attr("href", href, true, false)) + " target=\"_blank\" title=\"Avaa palvelukartta\" class=\"external-link\"><img" + (jade.attr("src", staticPath("images/logos/service-map-logo-" + (lang) + "-small.png"), true, false)) + (jade.attr("alt", t('assistive.to_frontpage'), false, false)) + " class=\"logo\"/></a></div>");;return buf.join("");
};

this["JST"]["views/templates/event-list-row"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),datetime = locals_.datetime,info_url = locals_.info_url,name = locals_.name;
buf.push("<div class=\"time\">" + (null == (jade_interp = datetime.date[0]) ? "" : jade_interp));
if ( datetime.date[1])
{
buf.push("&mdash;" + (null == (jade_interp = datetime.date[1]) ? "" : jade_interp));
}
if ( datetime.time)
{
buf.push("<br/>" + (null == (jade_interp = datetime.time) ? "" : jade_interp));
}
buf.push("</div><div class=\"name\"><a" + (jade.attr("href", "" + (info_url) + "", true, false)) + " target=\"_blank\" class=\"show-event-details\">" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</a></div>");;return buf.join("");
};

this["JST"]["views/templates/event"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),embedded_mode = locals_.embedded_mode,prevent_back = locals_.prevent_back,tAttr = locals_.tAttr,sp_name = locals_.sp_name,image = locals_.image,t = locals_.t,name = locals_.name,datetime = locals_.datetime,sp_phone = locals_.sp_phone,info_url = locals_.info_url,sp_url = locals_.sp_url,phoneI18n = locals_.phoneI18n,description = locals_.description,short_description = locals_.short_description,links = locals_.links;
buf.push("<div class=\"header\">");
if (!( embedded_mode || prevent_back))
{
buf.push("<a href=\"#\" role=\"button\" tabindex=\"0\" class=\"back-button vertically-aligned\">");
if ( tAttr(sp_name))
{
buf.push("<span class=\"icon-icon-back-bold\"></span><span class=\"sp-name\">" + (jade.escape(null == (jade_interp = tAttr(sp_name)) ? "" : jade_interp)) + "</span>");
}
buf.push("</a>");
}
buf.push("</div><div class=\"content limit-max-height\">");
if ( image)
{
buf.push("<img" + (jade.attr("src", "" + (image) + "", true, false)) + (jade.attr("alt", "" + (t('sidebar.picture_of')) + " " + (name) + "", true, false)) + " class=\"details-image\"/>");
}
buf.push("<div class=\"section main-info\"><a data-toggle=\"collapse\" data-parent=\"#event-view-container\" href=\"#main-info-details\" class=\"collapser\"><span class=\"icon icon-icon-events\">&nbsp;</span><h2><span>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</span></h2></a><div id=\"main-info-details\" class=\"section-content collapse in\"><div class=\"time\">");
if ( datetime.notice)
{
buf.push("<span class=\"notice\">" + (null == (jade_interp = datetime.notice) ? "" : jade_interp) + "</span><br/>");
}
if ( datetime.date)
{
buf.push("<span class=\"date\">" + (null == (jade_interp = datetime.date[0]) ? "" : jade_interp) + "</span>");
if ( datetime.date[1])
{
buf.push("&mdash;<br/><span class=\"date\">" + (null == (jade_interp = datetime.date[1]) ? "" : jade_interp) + "</span>");
}
}
if ( datetime.time)
{
buf.push("<br/><span class=\"time-of-day\">" + (null == (jade_interp = datetime.time) ? "" : jade_interp) + "</span>");
}
buf.push("</div>");
if ( tAttr(sp_name))
{
buf.push("<div class=\"sp-name\"><a href=\"#\">" + (jade.escape(null == (jade_interp = tAttr(sp_name)) ? "" : jade_interp)) + "</a></div>");
}
if ( sp_phone || info_url || tAttr(sp_url))
{
}
buf.push("<div class=\"contact-info\">");
if ( sp_phone)
{
buf.push("<span itemprop=\"telephone\"><a" + (jade.attr("href", "tel:" + (phoneI18n(sp_phone)) + "", true, false)) + " class=\"external-link\">" + (jade.escape(null == (jade_interp = sp_phone) ? "" : jade_interp)) + "</a></span>");
}
if ( sp_phone && (info_url || tAttr(sp_url)))
{
buf.push("&nbsp; | &nbsp;");
}
if ( info_url)
{
buf.push("<a" + (jade.attr("href", "" + (info_url) + "", true, false)) + " target=\"_blank\" class=\"external-link\">" + (jade.escape(null == (jade_interp = t('sidebar.further_info') + ' ') ? "" : jade_interp)) + "<span class=\"icon-icon-outbound-link\"></span></a>");
}
else if ( tAttr(sp_url))
{
buf.push("<a" + (jade.attr("href", "" + (tAttr(sp_url)) + "", true, false)) + " target=\"_blank\" class=\"external-link\">" + (jade.escape(null == (jade_interp = t('sidebar.further_info') + ' ') ? "" : jade_interp)) + "<span class=\"icon-icon-outbound-link\"></span></a>");
}
buf.push("</div>");
if ( description)
{
buf.push("<div class=\"description row\"><div class=\"col-md-12\">" + (null == (jade_interp = description) ? "" : jade_interp) + "</div></div>");
}
else if ( short_description)
{
buf.push("<div class=\"description row\"><div class=\"col-md-12\">" + (null == (jade_interp = short_description) ? "" : jade_interp) + "</div></div>");
}
buf.push("</div></div>");
if ( links && links.length)
{
buf.push("<div class=\"section\"><a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#web-services-details\" class=\"collapser collapsed\"><h3><span class=\"icon-icon-web-services\">&nbsp;</span>" + (jade.escape(null == (jade_interp = t('sidebar.web_services')) ? "" : jade_interp)) + "</h3><span class=\"short-text\">" + (jade.escape(null == (jade_interp = t('sidebar.service_count', {count: links.length})) ? "" : jade_interp)) + "</span></a><div id=\"web-services-details\" class=\"section-content collapse\"><ul>");
// iterate links
;(function(){
  var $$obj = links;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var link = $$obj[$index];

buf.push("<li><a" + (jade.attr("href", "" + (link.link) + "", true, false)) + " target=\"_blank\" class=\"external-link\">");
if ( link.name)
{
buf.push(jade.escape(null == (jade_interp = link.name) ? "" : jade_interp));
}
else
{
buf.push(jade.escape(null == (jade_interp = link.link) ? "" : jade_interp));
}
buf.push("<span class=\"icon-icon-outbound-link\"></span></a></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var link = $$obj[$index];

buf.push("<li><a" + (jade.attr("href", "" + (link.link) + "", true, false)) + " target=\"_blank\" class=\"external-link\">");
if ( link.name)
{
buf.push(jade.escape(null == (jade_interp = link.name) ? "" : jade_interp));
}
else
{
buf.push(jade.escape(null == (jade_interp = link.link) ? "" : jade_interp));
}
buf.push("<span class=\"icon-icon-outbound-link\"></span></a></li>");
    }

  }
}).call(this);

buf.push("</ul></div></div>");
}
buf.push("</div>");;return buf.join("");
};

this["JST"]["views/templates/exporting"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div class=\"exporting-header sm-control-button-wrapper\"><div id=\"exporting-context\" class=\"context-menu\"></div><a href=\"#\" role=\"button\" tabindex=\"1\" class=\"sm-control-button\"><span><strong>&lt;/&gt;</strong></span></a></div>");;return buf.join("");
};

this["JST"]["views/templates/feature-tour-start"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t;
buf.push("<a href=\"#\" tabindex=\"1\" class=\"prompt-button\">" + (null == (jade_interp = t('tour.start_prompt')) ? "" : jade_interp) + "<span class=\"close-button icon icon-icon-close\"></span></a>");;return buf.join("");
};

this["JST"]["views/templates/feedback-confirmation"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,unit = locals_.unit;
buf.push("<div class=\"modal-content\"><div class=\"section info-box modal-header\"><span class=\"icon icon-icon-feedback\"></span><a href=\"#\" data-dismiss=\"modal\" class=\"icon icon-icon-close\"></a><h3 class=\"modal-title\">" + (null == (jade_interp = t('feedback.form.header', {receiver: unit.name})) ? "" : jade_interp) + "</h3></div><div class=\"section modal-body confirmation\"><p>" + (jade.escape(null == (jade_interp = t('feedback.form.thanks')) ? "" : jade_interp)) + "</p><p><a href=\"#\" class=\"external-link processing-info\">" + (jade.escape(null == (jade_interp = t('feedback.form.processing_info')) ? "" : jade_interp)) + "</a><div class=\"submit-wrapper\"><div class=\"form-section\"><a href=\"#\" data-dismiss=\"modal\" class=\"ok-button dismiss\">Ok</a></div></div></p></div></div>");;return buf.join("");
};

this["JST"]["views/templates/feedback-form"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,unit = locals_.unit,title = locals_.title,first_name = locals_.first_name,service_request_type = locals_.service_request_type,description = locals_.description,can_be_published = locals_.can_be_published,accessibility_enabled = locals_.accessibility_enabled,email_enabled = locals_.email_enabled,email = locals_.email;
buf.push("<div class=\"modal-content\"><div class=\"section info-box modal-header\"><span class=\"icon icon-icon-feedback\"></span><a href=\"#\" data-dismiss=\"modal\" class=\"icon icon-icon-close\"></a><h3 class=\"modal-title\">" + (null == (jade_interp = t('feedback.form.header', {receiver: unit.name})) ? "" : jade_interp) + "</h3></div><div class=\"section modal-body\"><form class=\"settings-container\"><div class=\"form-section\"><label>" + (jade.escape(null == (jade_interp = t('feedback.form.subject')) ? "" : jade_interp)) + ":<input id=\"open311-title\" type=\"text\"" + (jade.attr("value", title, false, false)) + "/></label></div><div class=\"form-section\"><label>" + (jade.escape(null == (jade_interp = t('feedback.form.sender_name')) ? "" : jade_interp)) + ":<input id=\"open311-first_name\" type=\"text\"" + (jade.attr("value", first_name, false, false)) + "/></label></div><div class=\"form-section\"><label>" + (jade.escape(null == (jade_interp = t('feedback.form.type')) ? "" : jade_interp)) + ":</label><span class=\"form-type-elements settings-controllers\"><input id=\"blame\" type=\"radio\" name=\"open311-service_request_type\" value=\"BLAME\"" + (jade.attr("checked", (service_request_type=='BLAME'), true, false)) + "/><label for=\"blame\" class=\"mode-switch\">" + (jade.escape(null == (jade_interp = t('feedback.form.blame')) ? "" : jade_interp)) + "</label><input id=\"thank\" type=\"radio\" name=\"open311-service_request_type\" value=\"THANK\"" + (jade.attr("checked", (service_request_type=='THANK'), true, false)) + "/><label for=\"thank\" class=\"mode-switch\">" + (jade.escape(null == (jade_interp = t('feedback.form.thank')) ? "" : jade_interp)) + "</label><input id=\"idea\" type=\"radio\" name=\"open311-service_request_type\" value=\"IDEA\"" + (jade.attr("checked", (service_request_type=='IDEA'), true, false)) + "/><label for=\"idea\" class=\"mode-switch\">" + (jade.escape(null == (jade_interp = t('feedback.form.idea')) ? "" : jade_interp)) + "</label><input id=\"question\" type=\"radio\" name=\"open311-service_request_type\" value=\"QUESTION\"" + (jade.attr("checked", (service_request_type=='QUESTION'), true, false)) + "/><label for=\"question\" class=\"mode-switch\">" + (jade.escape(null == (jade_interp = t('feedback.form.question')) ? "" : jade_interp)) + "</label><input id=\"other\" type=\"radio\" name=\"open311-service_request_type\" value=\"OTHER\"" + (jade.attr("checked", (service_request_type=='OTHER'), true, false)) + "/><label for=\"other\" class=\"mode-switch\">" + (jade.escape(null == (jade_interp = t('feedback.form.other')) ? "" : jade_interp)) + "</label></span></div><div class=\"form-section\"><label class=\"description\">" + (jade.escape(null == (jade_interp = t('feedback.form.message')) ? "" : jade_interp)) + ":<span class=\"validation-error description hidden\"></span><textarea id=\"open311-description\" rows=\"10\" cols=\"40\" maxlength=\"5000\" required=\"required\">" + (null == (jade_interp = description) ? "" : jade_interp) + "</textarea></label></div><div class=\"form-section\"><label class=\"prominent\"><input id=\"open311-can_be_published\" type=\"checkbox\"" + (jade.attr("checked", can_be_published, true, false)) + "/>&nbsp;" + (jade.escape(null == (jade_interp = t('feedback.form.affirm_publication')) ? "" : jade_interp)) + "</label></div><div class=\"form-section\"><label class=\"prominent\"><input id=\"open311-accessibility_enabled\" type=\"checkbox\"" + (jade.attr("checked", accessibility_enabled, true, false)) + "/>&nbsp;" + (jade.escape(null == (jade_interp = t('feedback.form.accessibility_related')) ? "" : jade_interp)) + "</label><div" + (jade.cls(['hidden-section',accessibility_enabled ? "" : "hidden"], [null,true])) + "><label>" + (jade.escape(null == (jade_interp = t('feedback.form.accessibility_viewpoint')) ? "" : jade_interp)) + "&nbsp;</label><div id=\"accessibility-section\"></div></div></div><div class=\"form-section\"><label class=\"prominent\"><input id=\"open311-email_enabled\" type=\"checkbox\"" + (jade.attr("checked", email_enabled, true, false)) + "/>&nbsp;" + (jade.escape(null == (jade_interp = t('feedback.form.affirm_email')) ? "" : jade_interp)) + "</label><div" + (jade.cls(['hidden-section',email_enabled ? "" : "hidden"], [null,true])) + "><label>" + (jade.escape(null == (jade_interp = t('feedback.form.email_address')) ? "" : jade_interp)) + ":&nbsp;<input id=\"open311-email\" type=\"email\"" + (jade.attr("value", email, false, false)) + "/></label><p class=\"help-text\">" + (jade.escape(null == (jade_interp = t('feedback.form.email_safe_with_us')) ? "" : jade_interp)) + "</p></div></div><div class=\"form-section\"><div class=\"submit-wrapper\"><a href=\"#\" data-dismiss=\"modal\" class=\"cancel\">" + (jade.escape(null == (jade_interp = t('general.cancel')) ? "" : jade_interp)) + "</a><input type=\"submit\"" + (jade.attr("value", t('feedback.form.submit'), false, false)) + " class=\"ok-button\"/><a target=\"_blank\"" + (jade.attr("href", t('feedback.official_information'), false, false)) + " class=\"external-link processing-info\">" + (jade.escape(null == (jade_interp = t('feedback.form.processing_info')) ? "" : jade_interp)) + " <span class=\"icon-icon-outbound-link\"></span></a></div></div></form></div></div>");;return buf.join("");
};

this["JST"]["views/templates/feedback-list-row"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),output = locals_.output,id = locals_.id,service_request_id = locals_.service_request_id,extended_attributes = locals_.extended_attributes,humanDate = locals_.humanDate,updated_datetime = locals_.updated_datetime,description = locals_.description,status_notes = locals_.status_notes;
jade_mixins["preserveNewlines"] = function(input){
var block = (this && this.block), attributes = (this && this.attributes) || {};
output = input.replace(/(?:\r\n|\r|\n)/g, '<br />')
buf.push(null == (jade_interp = output) ? "" : jade_interp);
};
id = "request-" + service_request_id
buf.push("<a data-toggle=\"collapse\" data-parent=\"#feedback-details\"" + (jade.attr("href", "#"+id, true, false)) + " class=\"collapser collapsed\"><h5>" + (jade.escape(null == (jade_interp = extended_attributes.title) ? "" : jade_interp)) + "</h5><span class=\"date\">" + (jade.escape(null == (jade_interp = humanDate(updated_datetime).date[0]) ? "" : jade_interp)) + "</span></a><div" + (jade.attr("id", id, true, false)) + " class=\"section-content collapse\"><!--p= t('feedback.detailed_status.' + extended_attributes.detailed_status)--><p>");
jade_mixins["preserveNewlines"](description);
buf.push("</p><!-- p.answer--><!--  = t('feedback.updated_date')--><!--  | &nbsp;--><!--  = humanDate(updated_datetime).date[0]--><p class=\"answer\">");
jade_mixins["preserveNewlines"](status_notes);
buf.push("</p><!--p= service_name--></div><!--p= agency_responsible--><!-- TODO: add service names--><!--p= service_code--><!--p= status--><!--p= address--><!--p= id--><!--p= lat--><!--p= long--><!--p= service_request_id-->");;return buf.join("");
};

this["JST"]["views/templates/landing-title-view"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),isHidden = locals_.isHidden,staticPath = locals_.staticPath,lang = locals_.lang,t = locals_.t;
if (!( isHidden))
{
buf.push("<img" + (jade.attr("src", staticPath("images/logos/service-map-logo-" + (lang) + "-medium.png"), true, false)) + " alt=\"Service Map logo\" class=\"landing-logo\"/><span class=\"slogan\">" + (jade.escape(null == (jade_interp = t('sidebar.disclaimer')) ? "" : jade_interp)) + "</span>");
};return buf.join("");
};

this["JST"]["views/templates/language-selector"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),items = locals_.items;
// iterate items
;(function(){
  var $$obj = items;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var item = $$obj[index];

if ( index > 0)
{
buf.push("<span class=\"separator\"> | </span>");
}
buf.push("<a" + (jade.attr("href", item.link, true, false)) + (jade.attr("data-language", item.code, false, false)) + " tabindex=\"1\" class=\"external-link language\">" + (jade.escape(null == (jade_interp = item.name) ? "" : jade_interp)) + "</a>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var item = $$obj[index];

if ( index > 0)
{
buf.push("<span class=\"separator\"> | </span>");
}
buf.push("<a" + (jade.attr("href", item.link, true, false)) + (jade.attr("data-language", item.code, false, false)) + " tabindex=\"1\" class=\"external-link language\">" + (jade.escape(null == (jade_interp = item.name) ? "" : jade_interp)) + "</a>");
    }

  }
}).call(this);
;return buf.join("");
};

this["JST"]["views/templates/location-refresh-button"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div class=\"location-refresh-header sm-control-button-wrapper\"><a href=\"#!\" role=\"button\" tabindex=\"1\" class=\"sm-control-button location-button\"><span class=\"icon-icon-you-are-here\"></span></a></div>");;return buf.join("");
};

this["JST"]["views/templates/mixins/personalisation-mode"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;





;return buf.join("");
};

this["JST"]["views/templates/mixins/preserve-newlines"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;





;return buf.join("");
};

this["JST"]["views/templates/navigation-browse"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t;
buf.push("<span class=\"icon icon-icon-browse\"></span><span aria-hidden=\"true\" class=\"text\">" + (jade.escape(null == (jade_interp = t('sidebar.browse')) ? "" : jade_interp)) + "</span><span aria-hidden=\"true\" class=\"short-text\">" + (jade.escape(null == (jade_interp = t('sidebar.browse_short')) ? "" : jade_interp)) + "</span><h3 class=\"sr-only\">" + (jade.escape(null == (jade_interp = t('sidebar.browse')) ? "" : jade_interp)) + "</h3><span type=\"button\" class=\"action-button close-button\"><span class=\"icon-icon-close\"></span></span>");;return buf.join("");
};

this["JST"]["views/templates/navigation-header"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t;
buf.push("<h2 class=\"sr-only\">" + (null == (jade_interp = t('assistive.navigation')) ? "" : jade_interp) + "</h2><div class=\"search-container\"><div id=\"search-region\" role=\"link\" data-type=\"search\" tabindex=\"-1\" class=\"header search\"></div></div><div class=\"browse-container\"><div id=\"browse-region\" role=\"link\" data-type=\"browse\" tabindex=\"1\" class=\"header browse\"></div></div>");;return buf.join("");
};

this["JST"]["views/templates/navigation-layout"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<nav id=\"navigation-header\"></nav><main id=\"navigation-contents\"></main>");;return buf.join("");
};

this["JST"]["views/templates/navigation-search"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,input_query = locals_.input_query;
buf.push("<span class=\"icon icon-icon-search\"></span><h3 class=\"sr-only\">" + (null == (jade_interp = t('assistive.search')) ? "" : jade_interp) + "</h3><form class=\"input-container\"><input type=\"search\"" + (jade.attr("placeholder", t('sidebar.search'), false, false)) + (jade.attr("title", t('sidebar.search'), false, false)) + (jade.attr("value", input_query, false, false)) + " tabindex=\"1\" class=\"form-control\"/><span type=\"button\" class=\"action-button close-button\"><span class=\"icon-icon-close\"></span></span></form>");;return buf.join("");
};

this["JST"]["views/templates/personalisation"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),label = locals_.label,t = locals_.t;
jade_mixins["renderCity"] = function(id){
var block = (this && this.block), attributes = (this && this.attributes) || {};
label = "label-municipality-" + id
buf.push("<li data-group=\"city\"" + (jade.attr("data-type", id, true, false)) + "><a href=\"#\" role=\"button\"" + (jade.attr("aria-described-by", label, true, false)) + " tabindex=\"1\"><div class=\"icon\"><span" + (jade.cls(["icon-icon-coat-of-arms-" + (id) + ""], [false])) + "></span></div><span" + (jade.attr("id", label, true, false)) + " class=\"text\">" + (jade.escape(null == (jade_interp = t('municipality.' + id)) ? "" : jade_interp)) + "</span></a></li>");
};
buf.push("<div class=\"personalisation-header\"><div class=\"selected-personalisations\"></div><a href=\"#\" role=\"button\" tabindex=\"1\" class=\"personalisation-button\"><span class=\"icon-icon-personalise\"></span><h2 class=\"text\">" + (jade.escape(null == (jade_interp = t('personalisation.personalise')) ? "" : jade_interp)) + "</h2></a><a href=\"#\" role=\"button\" tabindex=\"1\" class=\"ok-button\">OK</a></div><div class=\"personalisation-content\"><!-- .section--><!--   h3= t('personalisation.my_location')--><!--   .location-controls--><!--     .input-container--><!--       input.form-control(type=\"text\", placeholder!=t('personalisation.enter_address'))--><!--     .link-container--><!--       a.select-on-map(href=\"#\")--><!--         != t('personalisation.select_on_map')--><div id=\"accessibility-personalisation\"></div><div class=\"section\"><h3>" + (jade.escape(null == (jade_interp = t('personalisation.city')) ? "" : jade_interp)) + "</h3><ul class=\"personalisations coats-of-arms\">");
jade_mixins["renderCity"]('helsinki');
jade_mixins["renderCity"]('espoo');
jade_mixins["renderCity"]('vantaa');
jade_mixins["renderCity"]('kauniainen');
buf.push("</ul></div></div><div class=\"personalisation-message sm-popup open\"><div class=\"arrow top\"></div><span class=\"icon icon-icon-wheelchair\"></span><span type=\"button\" class=\"close-button\"><span class=\"icon-icon-close\"></span></span><a href=\"#\">" + (jade.escape(null == (jade_interp = t('personalisation.personalisation_message')) ? "" : jade_interp)) + "</a></div>");;return buf.join("");
};

this["JST"]["views/templates/popup_cluster"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),names = locals_.names,overflow_message = locals_.overflow_message;
buf.push("<div class=\"unit-name\"><ul></ul>");
// iterate names
;(function(){
  var $$obj = names;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var name = $$obj[$index];

buf.push("<li>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var name = $$obj[$index];

buf.push("<li>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</li>");
    }

  }
}).call(this);

buf.push("<div class=\"overflow\">" + (jade.escape(null == (jade_interp = overflow_message) ? "" : jade_interp)) + "</div></div>");;return buf.join("");
};

this["JST"]["views/templates/position-popup"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),name = locals_.name,detected = locals_.detected;
buf.push("<div class=\"position-wrap sm-popup open\"><div class=\"arrow bottom\"></div><div class=\"icon icon-icon-forward\"></div><div class=\"address\">" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</div>");
if ( detected)
{
buf.push("<div class=\"type\">Current location</div>");
}
buf.push("</div>");;return buf.join("");
};

this["JST"]["views/templates/position"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),icon_class = locals_.icon_class,name = locals_.name,t = locals_.t,origin = locals_.origin,neighborhood = locals_.neighborhood,uppercaseFirst = locals_.uppercaseFirst,tAttr = locals_.tAttr;
buf.push("<div class=\"header\"><div class=\"mobile-header\"><div class=\"header-content\"><div" + (jade.cls(['icon',icon_class], [null,true])) + "></div><span class=\"icon-icon-close\"></span><h2><span>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</span></h2></div></div></div><div class=\"content position limit-max-height\"><div class=\"map-active-area\"></div><div class=\"section main-info\"><div class=\"header\"><div" + (jade.cls(['icon',icon_class], [null,true])) + "></div><span class=\"icon-icon-close\"></span><h2><span>" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</span></h2></div><div class=\"section-content\"><p>" + (jade.escape(null == (jade_interp = t('position.type.' + origin)) ? "" : jade_interp)));
if ( neighborhood)
{
buf.push("<br/>" + (jade.escape(null == (jade_interp = uppercaseFirst(t('district.neighborhood'))) ? "" : jade_interp)) + ": " + (jade.escape(null == (jade_interp = tAttr(neighborhood.get('name'))) ? "" : jade_interp)));
}
buf.push("<br/><a id=\"add-circle\" href=\"#\" class=\"blue-link\">" + (jade.escape(null == (jade_interp = t('position.show_within_radius')) ? "" : jade_interp)) + "</a></p></div></div><div class=\"section route-section\"></div><div class=\"section division-section\"><a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#service-details\" class=\"collapser collapsed route\"><h3><span class=\"icon icon-icon-show-service-points\"></span>" + (jade.escape(null == (jade_interp = t('position.services.header')) ? "" : jade_interp)) + "</h3></a><div id=\"service-details\" class=\"section-content collapse\"><h4>" + (jade.escape(null == (jade_interp = t('position.services.info')) ? "" : jade_interp)) + "</h4><div class=\"area-services-placeholder\"></div></div></div><div class=\"section division-section\"><a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#division-details\" class=\"collapser collapsed route\"><h3><span class=\"icon icon-icon-areas-and-districts\"></span>" + (jade.escape(null == (jade_interp = t('position.district.header')) ? "" : jade_interp)) + "</h3></a><div id=\"division-details\" class=\"section-content collapse\"><div class=\"admin-div-placeholder\"></div></div></div></div>");;return buf.join("");
};

this["JST"]["views/templates/radius-controls"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,values = locals_.values,selected = locals_.selected,humanDistance = locals_.humanDistance;
buf.push("<label>" + (jade.escape(null == (jade_interp = t('sidebar.radius_description')) ? "" : jade_interp)) + "&nbsp;<select id=\"radius\" name=\"radius\">");
// iterate values
;(function(){
  var $$obj = values;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var value = $$obj[$index];

buf.push("<option" + (jade.attr("value", value, true, false)) + (jade.attr("selected", value==selected ? "" : null, true, false)) + ">" + (jade.escape(null == (jade_interp = humanDistance(value)) ? "" : jade_interp)) + "</option>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var value = $$obj[$index];

buf.push("<option" + (jade.attr("value", value, true, false)) + (jade.attr("selected", value==selected ? "" : null, true, false)) + ">" + (jade.escape(null == (jade_interp = humanDistance(value)) ? "" : jade_interp)) + "</option>");
    }

  }
}).call(this);

buf.push("</select></label>");;return buf.join("");
};

this["JST"]["views/templates/route-controllers"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),params = locals_.params,t = locals_.t,origin = locals_.origin,destination = locals_.destination,time_mode = locals_.time_mode,undefined = locals_.undefined,disable_keyboard = locals_.disable_keyboard,time = locals_.time,is_today = locals_.is_today,date = locals_.date;
buf.push("<div class=\"route-controllers settings-controllers\"><div class=\"row transit-endpoints\"><div class=\"col-sm-6 col-xs-12 transit-start\"><div class=\"input-wrapper\">");
if ( params.getOrigin().isPending() && !params.getOrigin().isDetectedLocation())
{
buf.push("<input type=\"text\"" + (jade.attr("placeholder", t('transit.input_placeholder'), false, false)) + " data-endpoint=\"origin\" class=\"endpoint\"/>");
}
else
{
buf.push("<div data-route-node=\"start\"" + (jade.cls(['preset',origin.lock === true ? 'locked' : 'unlocked'], [null,true])) + "><div class=\"endpoint-name\">" + (null == (jade_interp = origin.name) ? "" : jade_interp) + "</div></div>");
}
buf.push("</div></div><div class=\"col-sm-6 col-xs-12 transit-end\"><div class=\"input-wrapper\">");
if ( params.getDestination().isPending() && !params.getDestination().isDetectedLocation())
{
buf.push("<input type=\"text\"" + (jade.attr("placeholder", t('transit.input_placeholder'), false, false)) + " data-endpoint=\"destination\" class=\"endpoint\"/>");
}
else
{
buf.push("<div data-route-node=\"end\"" + (jade.cls(['preset',destination.lock === true ? 'locked' : 'unlocked'], [null,true])) + "><div class=\"endpoint-name\">" + (null == (jade_interp = destination.name) ? "" : jade_interp) + "</div></div>");
}
buf.push("</div></div><a href=\"#\" class=\"swap-endpoints\"><span class=\"icon-icon-forward\"></span></a></div><div class=\"row transit-time\"><div class=\"col-xs-12\"><a data-value=\"depart\"" + (jade.cls(['time-mode','mode-switch','unlocked',time_mode === 'depart' ? 'selected' : undefined], [null,null,null,true])) + ">" + (jade.escape(null == (jade_interp = t('transit.depart')) ? "" : jade_interp)) + "</a><a data-value=\"arrive\"" + (jade.cls(['time-mode','mode-switch','unlocked',time_mode === 'arrive' ? 'selected' : undefined], [null,null,null,true])) + ">" + (jade.escape(null == (jade_interp = t('transit.arrive')) ? "" : jade_interp)) + "</a>");
if ( params.isTimeSet() || time_mode == 'arrive')
{
buf.push("<div class=\"input-wrapper\">");
if ( disable_keyboard)
{
buf.push("<input type=\"text\"" + (jade.attr("readonly", "" + (disable_keyboard) + "", true, false)) + (jade.attr("value", "" + (time) + "", true, false)) + " size=\"5\" class=\"time\"/>");
}
else
{
buf.push("<input type=\"text\"" + (jade.attr("value", "" + (time) + "", true, false)) + " size=\"5\" class=\"time\"/>");
}
buf.push("</div><div class=\"input-wrapper\">");
if ( is_today)
{
buf.push("<span class=\"preset preset-current-date\">" + (jade.escape(null == (jade_interp = t('time.today')) ? "" : jade_interp)) + "</span>");
}
else
{
if ( disable_keyboard)
{
buf.push("<input type=\"text\"" + (jade.attr("readonly", "" + (disable_keyboard) + "", true, false)) + (jade.attr("value", "" + (date) + "", true, false)) + " size=\"10\" class=\"date\"/>");
}
else
{
buf.push("<input type=\"text\"" + (jade.attr("value", "" + (date) + "", true, false)) + " size=\"10\" class=\"date\"/>");
}
}
buf.push("</div>");
}
else
{
buf.push("<div class=\"input-wrapper\"><div class=\"preset preset-current-time unlocked\">" + (jade.escape(null == (jade_interp = t('transit.now')) ? "" : jade_interp)) + "</div></div>");
}
buf.push("</div></div></div>");;return buf.join("");
};

this["JST"]["views/templates/route-settings-header"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),origin_is_pending = locals_.origin_is_pending,undefined = locals_.undefined,profile_set = locals_.profile_set,profiles = locals_.profiles,transport_icons = locals_.transport_icons,t = locals_.t,origin_name = locals_.origin_name;
buf.push("<a href=\"#\"" + (jade.cls(['settings-summary',!origin_is_pending ? 'de-emphasized' : undefined], [null,true])) + "><span class=\"icon-icon-settings\"></span><div class=\"icons\">");
if ( profile_set)
{
// iterate profiles
;(function(){
  var $$obj = profiles;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var profile = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',profile['icon']], [null,false])) + "></span>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var profile = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',profile['icon']], [null,false])) + "></span>");
    }

  }
}).call(this);

if ( transport_icons.length)
{
buf.push("<span class=\"separator\">&middot;</span>");
}
}
// iterate transport_icons
;(function(){
  var $$obj = transport_icons;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var icon = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',icon], [null,false])) + "></span>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var icon = $$obj[$index];

buf.push("<span" + (jade.cls(['icon',icon], [null,false])) + "></span>");
    }

  }
}).call(this);

buf.push("</div><span class=\"origin-name\">");
if ( !origin_is_pending)
{
buf.push(jade.escape(null == (jade_interp = t('transit.route_settings.from')) ? "" : jade_interp));
}
buf.push((jade.escape(null == (jade_interp = ' ' + origin_name) ? "" : jade_interp)) + "</span></a><div class=\"settings-header\"><h3><span class=\"icon-icon-settings\"></span>" + (jade.escape(null == (jade_interp = t('transit.route_settings.route_settings')) ? "" : jade_interp)) + "</h3><a href=\"#\" role=\"button\" tabindex=\"0\" class=\"ok-button\">OK</a></div>");;return buf.join("");
};

this["JST"]["views/templates/route-settings"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t;
buf.push("<div class=\"route-settings-header\"></div><div class=\"settings-content\"><div class=\"route-controllers\"></div><h3>" + (jade.escape(null == (jade_interp = t('transit.route_settings.accessibility_options')) ? "" : jade_interp)) + "</h3><div class=\"accessibility-viewpoint-part\"></div><h3>" + (jade.escape(null == (jade_interp = t('transit.route_settings.transport_options')) ? "" : jade_interp)) + "</h3><div class=\"transport_mode_controls\"></div></div>");;return buf.join("");
};

this["JST"]["views/templates/route"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),transit_icon = locals_.transit_icon,t = locals_.t;
buf.push("<a data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#route-details\" class=\"collapser collapsed route\"><h3><span id=\"route-section-icon\"" + (jade.cls([transit_icon], [false])) + ">&nbsp;</span>" + (jade.escape(null == (jade_interp = t('sidebar.route_here')) ? "" : jade_interp)) + "</h3><span class=\"short-text\"><span class=\"length\"></span><!--= itinerary.duration--></span></a><div id=\"route-details\" class=\"section-content collapse\"><div class=\"route-settings settings-container\"></div><div class=\"route-summary\"><div class=\"route-spinner\"></div></div></div>");;return buf.join("");
};

this["JST"]["views/templates/routing-leg-summary"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<span class=\"foo\">foobar</span>");;return buf.join("");
};

this["JST"]["views/templates/routing-summary"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),skip_route = locals_.skip_route,itinerary_choices = locals_.itinerary_choices,selected_itinerary_index = locals_.selected_itinerary_index,undefined = locals_.undefined,t = locals_.t,itinerary = locals_.itinerary,profile_set = locals_.profile_set;
buf.push("<div class=\"route-settings\"></div>");
if ( !skip_route)
{
if ( itinerary_choices.length > 1)
{
buf.push("<ul class=\"route-selector\">");
// iterate itinerary_choices
;(function(){
  var $$obj = itinerary_choices;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var index = $$obj[$index];

buf.push("<li" + (jade.cls([index === selected_itinerary_index ? 'selected' : undefined], [true])) + "><a href=\"#\"" + (jade.attr("data-index", "" + (index) + "", true, false)) + "><span class=\"route-label\">" + (jade.escape(null == (jade_interp = t('transit.route')) ? "" : jade_interp)) + "</span>&nbsp;" + (jade.escape(null == (jade_interp = (index + 1)) ? "" : jade_interp)) + "</a></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var index = $$obj[$index];

buf.push("<li" + (jade.cls([index === selected_itinerary_index ? 'selected' : undefined], [true])) + "><a href=\"#\"" + (jade.attr("data-index", "" + (index) + "", true, false)) + "><span class=\"route-label\">" + (jade.escape(null == (jade_interp = t('transit.route')) ? "" : jade_interp)) + "</span>&nbsp;" + (jade.escape(null == (jade_interp = (index + 1)) ? "" : jade_interp)) + "</a></li>");
    }

  }
}).call(this);

buf.push("</ul>");
}
buf.push("<div class=\"route-info\"><span class=\"icon-icon-opening-hours\"></span>&nbsp;" + (jade.escape(null == (jade_interp = itinerary.duration) ? "" : jade_interp)) + "&nbsp;<span class=\"icon-icon-by-foot\"></span>&nbsp;" + (jade.escape(null == (jade_interp = itinerary.walk_distance) ? "" : jade_interp)) + "<a href=\"#\" class=\"show-map\">" + (jade.escape(null == (jade_interp = t('transit.show_on_map')) ? "" : jade_interp)) + "</a></div><div class=\"legs\">");
// iterate itinerary.legs
;(function(){
  var $$obj = itinerary.legs;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var leg = $$obj[index];

buf.push("<div" + (jade.cls(['leg',index === itinerary.legs.length - 1 ? 'last-leg' : undefined], [null,true])) + "><div" + (jade.cls(['leg-line',"" + (leg.transit_color_class) + "-background-color"], [null,true])) + "></div><div" + (jade.cls(['leg-start-point',"" + (leg.transit_color_class) + "-border-color"], [null,true])) + "></div><div class=\"row layover-row\"><div class=\"col-xs-2\">" + (jade.escape(null == (jade_interp = leg.start_time) ? "" : jade_interp)) + "</div><div class=\"col-xs-1\"></div><div class=\"col-xs-9 bold\">" + (jade.escape(null == (jade_interp = leg.start_location) ? "" : jade_interp)) + "</div></div><a data-toggle=\"collapse\" data-parent=\"#route-details\"" + (jade.attr("href", "#leg-" + (index) + "-details", true, false)) + (jade.cls(['collapser','collapsed',leg.has_warnings ? 'has-warnings' : ''], [null,null,true])) + "><div class=\"row transit-row\"><div" + (jade.cls(['col-xs-2','leg-icon',"" + (leg.transit_color_class) + "-color"], [null,null,true])) + "><span" + (jade.cls(['icon',leg.icon], [null,false])) + "></span></div><div class=\"col-xs-1\"></div><div class=\"col-xs-9\"><span class=\"distance\">" + (jade.escape(null == (jade_interp = leg.distance) ? "" : jade_interp)) + "</span><div class=\"text\">" + (jade.escape(null == (jade_interp = leg.transit_mode + ' ') ? "" : jade_interp)) + "<span" + (jade.cls(['route',"" + (leg.transit_color_class) + "-color"], [null,true])) + ">" + (jade.escape(null == (jade_interp = leg.route) ? "" : jade_interp)) + "</span>" + (jade.escape(null == (jade_interp = ' ' + leg.transit_destination) ? "" : jade_interp)) + "</div></div></div></a><div" + (jade.attr("id", "leg-" + (index) + "-details", true, false)) + " class=\"steps collapse\">");
// iterate leg.steps
;(function(){
  var $$obj = leg.steps;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var step = $$obj[$index];

buf.push("<div" + (jade.cls(['row','step',step.warning ? 'has-warnings' : ''], [null,null,true])) + "><div class=\"col-xs-9 col-xs-offset-3\"><span class=\"text\">" + (jade.escape(null == (jade_interp = step.text) ? "" : jade_interp)) + "</span>");
if ( step.time)
{
buf.push("&nbsp;(" + (jade.escape(null == (jade_interp = step.time) ? "" : jade_interp)) + ")");
}
if ( step.warning)
{
buf.push("<span class=\"warning\">&nbsp;-&nbsp;" + (jade.escape(null == (jade_interp = step.warning) ? "" : jade_interp)) + "</span>");
}
buf.push("</div></div>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var step = $$obj[$index];

buf.push("<div" + (jade.cls(['row','step',step.warning ? 'has-warnings' : ''], [null,null,true])) + "><div class=\"col-xs-9 col-xs-offset-3\"><span class=\"text\">" + (jade.escape(null == (jade_interp = step.text) ? "" : jade_interp)) + "</span>");
if ( step.time)
{
buf.push("&nbsp;(" + (jade.escape(null == (jade_interp = step.time) ? "" : jade_interp)) + ")");
}
if ( step.warning)
{
buf.push("<span class=\"warning\">&nbsp;-&nbsp;" + (jade.escape(null == (jade_interp = step.warning) ? "" : jade_interp)) + "</span>");
}
buf.push("</div></div>");
    }

  }
}).call(this);

buf.push("</div></div>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var leg = $$obj[index];

buf.push("<div" + (jade.cls(['leg',index === itinerary.legs.length - 1 ? 'last-leg' : undefined], [null,true])) + "><div" + (jade.cls(['leg-line',"" + (leg.transit_color_class) + "-background-color"], [null,true])) + "></div><div" + (jade.cls(['leg-start-point',"" + (leg.transit_color_class) + "-border-color"], [null,true])) + "></div><div class=\"row layover-row\"><div class=\"col-xs-2\">" + (jade.escape(null == (jade_interp = leg.start_time) ? "" : jade_interp)) + "</div><div class=\"col-xs-1\"></div><div class=\"col-xs-9 bold\">" + (jade.escape(null == (jade_interp = leg.start_location) ? "" : jade_interp)) + "</div></div><a data-toggle=\"collapse\" data-parent=\"#route-details\"" + (jade.attr("href", "#leg-" + (index) + "-details", true, false)) + (jade.cls(['collapser','collapsed',leg.has_warnings ? 'has-warnings' : ''], [null,null,true])) + "><div class=\"row transit-row\"><div" + (jade.cls(['col-xs-2','leg-icon',"" + (leg.transit_color_class) + "-color"], [null,null,true])) + "><span" + (jade.cls(['icon',leg.icon], [null,false])) + "></span></div><div class=\"col-xs-1\"></div><div class=\"col-xs-9\"><span class=\"distance\">" + (jade.escape(null == (jade_interp = leg.distance) ? "" : jade_interp)) + "</span><div class=\"text\">" + (jade.escape(null == (jade_interp = leg.transit_mode + ' ') ? "" : jade_interp)) + "<span" + (jade.cls(['route',"" + (leg.transit_color_class) + "-color"], [null,true])) + ">" + (jade.escape(null == (jade_interp = leg.route) ? "" : jade_interp)) + "</span>" + (jade.escape(null == (jade_interp = ' ' + leg.transit_destination) ? "" : jade_interp)) + "</div></div></div></a><div" + (jade.attr("id", "leg-" + (index) + "-details", true, false)) + " class=\"steps collapse\">");
// iterate leg.steps
;(function(){
  var $$obj = leg.steps;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var step = $$obj[$index];

buf.push("<div" + (jade.cls(['row','step',step.warning ? 'has-warnings' : ''], [null,null,true])) + "><div class=\"col-xs-9 col-xs-offset-3\"><span class=\"text\">" + (jade.escape(null == (jade_interp = step.text) ? "" : jade_interp)) + "</span>");
if ( step.time)
{
buf.push("&nbsp;(" + (jade.escape(null == (jade_interp = step.time) ? "" : jade_interp)) + ")");
}
if ( step.warning)
{
buf.push("<span class=\"warning\">&nbsp;-&nbsp;" + (jade.escape(null == (jade_interp = step.warning) ? "" : jade_interp)) + "</span>");
}
buf.push("</div></div>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var step = $$obj[$index];

buf.push("<div" + (jade.cls(['row','step',step.warning ? 'has-warnings' : ''], [null,null,true])) + "><div class=\"col-xs-9 col-xs-offset-3\"><span class=\"text\">" + (jade.escape(null == (jade_interp = step.text) ? "" : jade_interp)) + "</span>");
if ( step.time)
{
buf.push("&nbsp;(" + (jade.escape(null == (jade_interp = step.time) ? "" : jade_interp)) + ")");
}
if ( step.warning)
{
buf.push("<span class=\"warning\">&nbsp;-&nbsp;" + (jade.escape(null == (jade_interp = step.warning) ? "" : jade_interp)) + "</span>");
}
buf.push("</div></div>");
    }

  }
}).call(this);

buf.push("</div></div>");
    }

  }
}).call(this);

buf.push("<div class=\"end\"><span" + (jade.cls(['leg-end-point','icon-icon-expand',"" + (itinerary.legs[itinerary.legs.length - 1].transit_color_class) + "-color"], [null,null,true])) + "></span><div class=\"row layover-row\"><div class=\"col-xs-2\"><span class=\"time\">" + (jade.escape(null == (jade_interp = itinerary.end.time) ? "" : jade_interp)) + "</span></div><div class=\"col-xs-1\"></div><div class=\"col-xs-9\">");
if ( itinerary.end.address)
{
buf.push("<span class=\"bold\">" + (jade.escape(null == (jade_interp = itinerary.end.address) ? "" : jade_interp)) + "</span>&nbsp;-&nbsp;");
}
buf.push("<span>" + (jade.escape(null == (jade_interp = itinerary.end.name) ? "" : jade_interp)) + "</span></div></div></div>");
if ( !profile_set)
{
buf.push("<a href=\"#\" class=\"accessibility-viewpoint\"><span class=\"icon icon-icon-wheelchair\"></span>" + (jade.escape(null == (jade_interp = t('transit.accessibility_not_filtered')) ? "" : jade_interp)) + "</a>");
}
buf.push("</div>");
};return buf.join("");
};

this["JST"]["views/templates/search-layout"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),noResults = locals_.noResults,t = locals_.t,query = locals_.query;
if ( noResults)
{
buf.push("<ul class=\"main-list\"><li class=\"info-box\"><p>" + (jade.escape(null == (jade_interp = t('sidebar.no_search_results')) ? "" : jade_interp)) + "<br/>" + (jade.escape(null == (jade_interp = query) ? "" : jade_interp)) + "</p></li></ul>");
}
else
{
buf.push("<div class=\"address-region\"></div><div class=\"service-region\"></div><div class=\"unit-region\"></div>");
};return buf.join("");
};

this["JST"]["views/templates/search-result"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),object_type = locals_.object_type,rootId = locals_.rootId,root_services = locals_.root_services,undefined = locals_.undefined,name = locals_.name,specifier_text = locals_.specifier_text,distance = locals_.distance,humanDistance = locals_.humanDistance,shortcomings = locals_.shortcomings,humanShortcomings = locals_.humanShortcomings;
buf.push("<a href=\"#\" class=\"search-result\">");
if ( object_type == 'service')
{
buf.push("<span class=\"icon icon-icon-browse\"></span>");
}
if ( object_type == 'unit')
{
rootId = (root_services !== undefined && root_services.length) ? root_services[0] : 0
buf.push("<div" + (jade.cls(["color-ball service-background-color-" + (rootId) + ""], [true])) + "></div>");
}
if ( object_type == 'address')
{
buf.push("<span class=\"icon icon-icon-address\"></span>");
}
buf.push("<span class=\"title\">" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</span><span class=\"specifier\">" + (jade.escape(null == (jade_interp = specifier_text) ? "" : jade_interp)) + "</span>");
if ( distance !== undefined)
{
buf.push("<span class=\"specifier distance\">" + (jade.escape(null == (jade_interp = humanDistance(distance)) ? "" : jade_interp)) + "</span>");
}
if ( shortcomings !== undefined)
{
buf.push("<span class=\"specifier shortcomings\">" + (jade.escape(null == (jade_interp = humanShortcomings(shortcomings)) ? "" : jade_interp)) + "</span>");
}
buf.push("</a>");;return buf.join("");
};

this["JST"]["views/templates/search-results"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),hidden = locals_.hidden,t = locals_.t,expanded = locals_.expanded,onlyResultType = locals_.onlyResultType,crumb = locals_.crumb,header = locals_.header,comparatorKey = locals_.comparatorKey,controls = locals_.controls,showAll = locals_.showAll,target = locals_.target,showMore = locals_.showMore;
if ( !hidden)
{
buf.push("<h2 class=\"sr-only\">" + (jade.escape(null == (jade_interp = t('assistive.search_results')) ? "" : jade_interp)) + "</h2>");
if ( expanded)
{
buf.push("<div class=\"header-item expanded-search-results\"><div class=\"header-column-main\">");
if ( !onlyResultType)
{
buf.push("<a href=\"#\" role=\"button\" tabindex=\"0\" class=\"back-button\"><span class=\"icon-icon-back-bold\"></span></a>");
}
buf.push("<span class=\"breadcrumbs\"><div class=\"crumb\">" + (jade.escape(null == (jade_interp = crumb) ? "" : jade_interp)) + "</div></span><br/>" + (null == (jade_interp = header) ? "" : jade_interp) + "</div><div class=\"header-column-sort\"><a href=\"#\" class=\"sorting\">" + (jade.escape(null == (jade_interp = t('search.sort_label')) ? "" : jade_interp)) + ":<br/>" + (null == (jade_interp = t('search.sort.' + comparatorKey)) ? "" : jade_interp) + "</a></div></div><div id=\"list-controls\"" + (jade.cls(['header-item',controls ? '' : 'hidden'], [null,true])) + "></div>");
}
else
{
buf.push("<div class=\"header-item\">" + (null == (jade_interp = header) ? "" : jade_interp) + "</div>");
}
buf.push("<div class=\"result-contents\"></div>");
if ( showAll)
{
buf.push("<a href=\"#\"" + (jade.attr("data-target", target, false, false)) + " class=\"show-prompt show-all\">" + (null == (jade_interp = showAll) ? "" : jade_interp) + "</a>");
}
if ( showMore)
{
buf.push("<a href=\"#\" class=\"show-prompt show-more\"><div class=\"text-content\">" + (jade.escape(null == (jade_interp = t('sidebar.scroll_for_more')) ? "" : jade_interp)) + "</div><div class=\"spinner-container\"></div></a>");
}
};return buf.join("");
};

this["JST"]["views/templates/service-cart"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),minimized = locals_.minimized,t = locals_.t,layers = locals_.layers,checked = locals_.checked,layer_id = locals_.layer_id,cls = locals_.cls,items = locals_.items;
if ( minimized)
{
buf.push("<li class=\"personalisation-container\"><a tabindex=\"1\" role=\"button\" class=\"maximizer\"><span class=\"icon-icon-map-options\"></span><h2 class=\"sr-only\">" + (jade.escape(null == (jade_interp = t('service_cart.currently_on_map')) ? "" : jade_interp)) + "</h2></a></li>");
}
else
{
buf.push("<li class=\"info-box\"><h2>" + (jade.escape(null == (jade_interp = t('service_cart.currently_on_map')) ? "" : jade_interp)) + "<span class=\"button cart-close-button\"><span class=\"icon-icon-close\"></span></span></h2></li><li class=\"map-layer\"><div class=\"map-layers\"><span class=\"layer-icon icon-icon-map-options\"></span><fieldset><legend>" + (jade.escape(null == (jade_interp = t('service_cart.background_map')) ? "" : jade_interp)) + "</legend>");
// iterate layers
;(function(){
  var $$obj = layers;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var layer = $$obj[$index];

if ( layer.selected)
{
checked = 'checked'
}
else
{
checked = null
}
layer_id = 'layer-' + layer.name
buf.push("<label" + (jade.attr("data-layer", layer.name, true, false)) + (jade.attr("for", layer_id, false, false)) + " class=\"layer\"><input type=\"radio\" name=\"map-layers\"" + (jade.attr("id", layer_id, false, false)) + (jade.attr("value", layer.name, false, false)) + (jade.attr("checked", checked, true, false)) + (jade.cls([cls], [true])) + "/>&nbsp;" + (jade.escape(null == (jade_interp = t('service_cart.' + layer.name)) ? "" : jade_interp)) + "</label>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var layer = $$obj[$index];

if ( layer.selected)
{
checked = 'checked'
}
else
{
checked = null
}
layer_id = 'layer-' + layer.name
buf.push("<label" + (jade.attr("data-layer", layer.name, true, false)) + (jade.attr("for", layer_id, false, false)) + " class=\"layer\"><input type=\"radio\" name=\"map-layers\"" + (jade.attr("id", layer_id, false, false)) + (jade.attr("value", layer.name, false, false)) + (jade.attr("checked", checked, true, false)) + (jade.cls([cls], [true])) + "/>&nbsp;" + (jade.escape(null == (jade_interp = t('service_cart.' + layer.name)) ? "" : jade_interp)) + "</label>");
    }

  }
}).call(this);

buf.push("</fieldset></div></li>");
// iterate items
;(function(){
  var $$obj = items;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

buf.push("<li class=\"services\"><div class=\"service\"><div" + (jade.cls(["color-ball service-background-color-" + (item.root) + ""], [true])) + "></div><div" + (jade.cls(["service-name service-color-" + (item.root) + ""], [true])) + ">" + (jade.escape(null == (jade_interp = item.name) ? "" : jade_interp)) + "</div></div><a role=\"button\"" + (jade.attr("data-service", "" + (item.id) + "", true, false)) + " tabindex=\"1\" class=\"button close-button\"><span class=\"icon-icon-close\"></span><span class=\"sr-only\">" + (jade.escape(null == (jade_interp = t('general.remove')) ? "" : jade_interp)) + "</span></a></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var item = $$obj[$index];

buf.push("<li class=\"services\"><div class=\"service\"><div" + (jade.cls(["color-ball service-background-color-" + (item.root) + ""], [true])) + "></div><div" + (jade.cls(["service-name service-color-" + (item.root) + ""], [true])) + ">" + (jade.escape(null == (jade_interp = item.name) ? "" : jade_interp)) + "</div></div><a role=\"button\"" + (jade.attr("data-service", "" + (item.id) + "", true, false)) + " tabindex=\"1\" class=\"button close-button\"><span class=\"icon-icon-close\"></span><span class=\"sr-only\">" + (jade.escape(null == (jade_interp = t('general.remove')) ? "" : jade_interp)) + "</span></a></li>");
    }

  }
}).call(this);

};return buf.join("");
};

this["JST"]["views/templates/service-sidebar"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),options = locals_.options,t = locals_.t;
buf.push("<div class=\"container\">");
if ( options.showSearchBar)
{
buf.push("<a href=\"#\" data-type=\"search\" class=\"header search\"><span class=\"icon icon-icon-search\"></span><span class=\"input-container\"><input type=\"search\"" + (jade.attr("placeholder", t('sidebar.search'), false, false)) + " class=\"form-control\"/><span type=\"button\" class=\"close-button\"><span class=\"icon-icon-close\"></span></span></span></a><a href=\"#\" data-type=\"browse\" class=\"header browse\"><span class=\"icon icon-icon-browse\"></span><span class=\"text\">" + (jade.escape(null == (jade_interp = t('sidebar.browse')) ? "" : jade_interp)) + "</span><span type=\"button\" class=\"close-button\"><span class=\"icon-icon-close\"></span></span></a>");
}
buf.push("<div class=\"contents\">");
if (!( options.showSearchBar))
{
if ( options.showTitleBar)
{
buf.push("<div id=\"title-bar-container\"></div>");
}
}
buf.push("<div id=\"service-tree-container\"></div><div id=\"details-view-container\"></div><div id=\"event-view-container\"></div><div id=\"search-results-container\"><ul id=\"search-results\"></ul></div></div></div>");;return buf.join("");
};

this["JST"]["views/templates/service-tree"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,back = locals_.back,parent_item = locals_.parent_item,breadcrumbs = locals_.breadcrumbs,list_items = locals_.list_items;
buf.push("<h2 class=\"sr-only\">" + (jade.escape(null == (jade_interp = t('assistive.service_tree')) ? "" : jade_interp)) + "</h2><ul class=\"main-list navi service-tree limit-max-height\">");
if ( back)
{
buf.push("<li" + (jade.attr("data-service-id", back, false, false)) + (jade.attr("data-service-name", "" + (parent_item.name) + "", true, false)) + " data-slide-direction=\"right\" role=\"link\" tabindex=\"0\" class=\"service parent header-item\"><div" + (jade.cls(["vertically-aligned service-color-" + (parent_item.root_id) + ""], [true])) + "><span><span aria-hidden=\"true\"" + (jade.cls(["icon-icon-back-bold service-color-" + (parent_item.root_id) + ""], [true])) + "></span>");
if ( breadcrumbs.length)
{
buf.push("<span class=\"breadcrumbs\">");
// iterate breadcrumbs
;(function(){
  var $$obj = breadcrumbs;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var crumb = $$obj[index];

buf.push("<a href=\"#\"" + (jade.attr("data-service-id", crumb.serviceId, true, false)) + (jade.attr("data-service-name", crumb.serviceName, true, false)) + " data-slide-direction=\"right\" class=\"crumb blue-link\">" + (jade.escape(null == (jade_interp = crumb.serviceName) ? "" : jade_interp)) + "</a>");
if ( index + 1 != breadcrumbs.length)
{
buf.push("<span class=\"icon-icon-forward\"></span>");
}
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var crumb = $$obj[index];

buf.push("<a href=\"#\"" + (jade.attr("data-service-id", crumb.serviceId, true, false)) + (jade.attr("data-service-name", crumb.serviceName, true, false)) + " data-slide-direction=\"right\" class=\"crumb blue-link\">" + (jade.escape(null == (jade_interp = crumb.serviceName) ? "" : jade_interp)) + "</a>");
if ( index + 1 != breadcrumbs.length)
{
buf.push("<span class=\"icon-icon-forward\"></span>");
}
    }

  }
}).call(this);

buf.push("</span><br/>");
}
buf.push((jade.escape(null == (jade_interp = parent_item.name) ? "" : jade_interp)) + "</span></div></li>");
}
else
{
buf.push("<li class=\"info-box\">" + (jade.escape(null == (jade_interp = t('sidebar.browse_tip')) ? "" : jade_interp)) + "</li>");
}
// iterate list_items
;(function(){
  var $$obj = list_items;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

buf.push("<li" + (jade.attr("data-service-id", "" + (item.id) + "", true, false)) + (jade.attr("data-service-name", "" + (item.name) + "", true, false)) + (jade.attr("data-root-id", "" + (item.root_id) + "", true, false)) + " data-slide-direction=\"left\" role=\"link\" tabindex=\"0\"" + (jade.cls([item.classes], [false])) + ">");
if ( item.has_children)
{
buf.push("<span aria-hidden=\"true\" class=\"icon-icon-forward-bold\"></span>");
}
buf.push("<span class=\"service-name vertically-aligned\">" + (jade.escape(null == (jade_interp = item.name) ? "" : jade_interp)) + "</span><a href=\"#\" role=\"button\"" + (jade.cls(["" + (item.show_icon_classes) + ""], [true])) + ">");
if ( item.has_children)
{
buf.push("<div class=\"icon-icon-show-service-points\"></div>");
}
else
{
buf.push("<div class=\"icon-icon-show-service-points-single\"></div>");
}
buf.push("<div class=\"service-point-count\">" + (jade.escape(null == (jade_interp = item.unit_count) ? "" : jade_interp)) + "</div></a></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var item = $$obj[$index];

buf.push("<li" + (jade.attr("data-service-id", "" + (item.id) + "", true, false)) + (jade.attr("data-service-name", "" + (item.name) + "", true, false)) + (jade.attr("data-root-id", "" + (item.root_id) + "", true, false)) + " data-slide-direction=\"left\" role=\"link\" tabindex=\"0\"" + (jade.cls([item.classes], [false])) + ">");
if ( item.has_children)
{
buf.push("<span aria-hidden=\"true\" class=\"icon-icon-forward-bold\"></span>");
}
buf.push("<span class=\"service-name vertically-aligned\">" + (jade.escape(null == (jade_interp = item.name) ? "" : jade_interp)) + "</span><a href=\"#\" role=\"button\"" + (jade.cls(["" + (item.show_icon_classes) + ""], [true])) + ">");
if ( item.has_children)
{
buf.push("<div class=\"icon-icon-show-service-points\"></div>");
}
else
{
buf.push("<div class=\"icon-icon-show-service-points-single\"></div>");
}
buf.push("<div class=\"service-point-count\">" + (jade.escape(null == (jade_interp = item.unit_count) ? "" : jade_interp)) + "</div></a></li>");
    }

  }
}).call(this);

buf.push("</ul>");;return buf.join("");
};

this["JST"]["views/templates/service-units"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div class=\"unit-region\"></div>");;return buf.join("");
};

this["JST"]["views/templates/title-view"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,root = locals_.root,staticPath = locals_.staticPath,lang = locals_.lang;
buf.push("<h1 class=\"sr-only\">" + (null == (jade_interp = t('general.site_title')) ? "" : jade_interp) + "</h1><div class=\"feedback-prompt\"><a href=\"#\" data-uv-trigger=\"contact\" class=\"prompt-button\">" + (jade.escape(null == (jade_interp = t('app_feedback.prompt')) ? "" : jade_interp)) + "</a></div><div class=\"bottom-logo\"><a" + (jade.attr("href", root, true, false)) + " class=\"external-link\"><img" + (jade.attr("src", staticPath("images/logos/service-map-logo-" + (lang) + "-small.png"), true, false)) + (jade.attr("alt", t('assistive.to_frontpage'), false, false)) + " class=\"logo\"/></a></div>");;return buf.join("");
};

this["JST"]["views/templates/tour"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),first = locals_.first,last = locals_.last,next = locals_.next,length = locals_.length,t = locals_.t,staticPath = locals_.staticPath,content = locals_.content,examples = locals_.examples;
buf.push("<div class=\"popover tour\"><div class=\"arrow\"></div><div class=\"popover-header\">");
if ( !first)
{
if ( !last)
{
buf.push("<div class=\"progress-meter small\">" + (jade.escape(null == (jade_interp = next - 1) ? "" : jade_interp)) + "/" + (jade.escape(null == (jade_interp = length) ? "" : jade_interp)) + "</div>");
}
}
buf.push("<a href=\"#\" data-role=\"end\" class=\"close-button\">");
if ( !last)
{
buf.push("<span class=\"small\">" + (jade.escape(null == (jade_interp = t('tour.end')) ? "" : jade_interp)) + "</span>");
}
buf.push("<span class=\"icon icon-icon-close\"></span></a>");
if ( first)
{
buf.push("<img" + (jade.attr("src", staticPath('/images/berries-on-grass.png'), true, false)) + " class=\"header\"/>");
}
buf.push("</div><div" + (jade.cls(['popover-title',next == 1 ? 'first' : ''], [null,true])) + "></div><div class=\"popover-content\"><p>" + (jade.escape(null == (jade_interp = content) ? "" : jade_interp)) + "</p></div>");
if ( last)
{
buf.push("<ul class=\"popover-examples\">");
// iterate examples
;(function(){
  var $$obj = examples;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var e = $$obj[$index];

buf.push("<li><a href=\"#\"" + (jade.attr("data-service", e.service, true, false)) + " class=\"blue-link service\"><span class=\"icon icon-icon-search\"></span>" + (jade.escape(null == (jade_interp = e.name) ? "" : jade_interp)) + "</a></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var e = $$obj[$index];

buf.push("<li><a href=\"#\"" + (jade.attr("data-service", e.service, true, false)) + " class=\"blue-link service\"><span class=\"icon icon-icon-search\"></span>" + (jade.escape(null == (jade_interp = e.name) ? "" : jade_interp)) + "</a></li>");
    }

  }
}).call(this);

buf.push("</ul>");
}
buf.push("<div class=\"popover-navigation\">");
if ( !first)
{
buf.push("<button data-role=\"prev\" class=\"back btn btn-default\"><span class=\"icon icon-icon-back\"></span>" + (jade.escape(null == (jade_interp = t('tour.previous')) ? "" : jade_interp)) + "</button>");
if ( !last)
{
buf.push("<button data-role=\"next\" class=\"forward btn btn-default\">" + (jade.escape(null == (jade_interp = t('tour.next')) ? "" : jade_interp)) + "<span class=\"icon icon-icon-forward\"></span></button>");
}
else
{
buf.push("<button class=\"btn btn-default tour-success\">" + (jade.escape(null == (jade_interp = t('tour.tour_ok')) ? "" : jade_interp)) + "</button>");
}
}
else
{
buf.push("<button data-role=\"next\" class=\"btn btn-default\">" + (jade.escape(null == (jade_interp = t('tour.start')) ? "" : jade_interp)) + "</button>");
}
buf.push("</div></div>");;return buf.join("");
};

this["JST"]["views/templates/transport-mode-controls"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),label = locals_.label,selected = locals_.selected,uppercaseFirst = locals_.uppercaseFirst,t = locals_.t,transport_modes = locals_.transport_modes,undefined = locals_.undefined,public_modes = locals_.public_modes,bicycle_details_classes = locals_.bicycle_details_classes,transport_detailed_choices = locals_.transport_detailed_choices;
jade_mixins["renderMode"] = function(group, type, icon, activeViewpoints){
var block = (this && this.block), attributes = (this && this.attributes) || {};
label = "label-" + group + "-" + type
buf.push("<li" + (jade.attr("data-group", group, true, false)) + (jade.attr("data-type", type, true, false)) + (jade.cls([(activeViewpoints.indexOf(type) != -1 ? 'selected' : '')], [true])) + "><a href=\"#\" role=\"button\"" + (jade.attr("aria-pressed", selected, false, false)) + (jade.attr("aria-described-by", label, true, false)) + " tabindex=\"1\"><div class=\"icon\"><span" + (jade.cls(["icon-icon-" + (icon) + ""], [false])) + "></span></div><span" + (jade.attr("id", label, true, false)) + " class=\"text\">" + (null == (jade_interp = uppercaseFirst(t("personalisation." + type))) ? "" : jade_interp) + "</span></a></li>");
};
buf.push("<ul class=\"personalisations transport-modes\">");
jade_mixins["renderMode"]('transport', 'by_foot', 'by-foot', transport_modes);
jade_mixins["renderMode"]('transport', 'bicycle', 'bicycle', transport_modes);
jade_mixins["renderMode"]('transport', 'public_transport', 'public-transport', transport_modes);
jade_mixins["renderMode"]('transport', 'car', 'car', transport_modes);
buf.push("</ul><ul" + (jade.cls(['personalisations','transport-details','public-details',transport_modes.indexOf('public_transport') != -1 ? undefined : 'hidden'], [null,null,null,true])) + "><div class=\"arrow top\"></div>");
jade_mixins["renderMode"]('transport_detailed_choices', 'bus', 'bus', public_modes);
jade_mixins["renderMode"]('transport_detailed_choices', 'tram', 'tram', public_modes);
jade_mixins["renderMode"]('transport_detailed_choices', 'metro', 'subway', public_modes);
jade_mixins["renderMode"]('transport_detailed_choices', 'train', 'train', public_modes);
jade_mixins["renderMode"]('transport_detailed_choices', 'ferry', 'ferry', public_modes);
buf.push("</ul><ul" + (jade.cls(['personalisations','transport-details','bicycle-details',bicycle_details_classes], [null,null,null,true])) + "><div class=\"arrow top\"></div><li data-type=\"bicycle_parked\"" + (jade.cls([transport_detailed_choices.bicycle.bicycle_parked ? 'selected' : ''], [true])) + "><a href=\"#\"><span class=\"text\">" + (null == (jade_interp = t('personalisation.bicycle_parked')) ? "" : jade_interp) + "</span></a></li><li data-type=\"bicycle_with\"" + (jade.cls([transport_detailed_choices.bicycle.bicycle_with ? 'selected' : ''], [true])) + "><a href=\"#\"><span class=\"text\">" + (null == (jade_interp = t('personalisation.bicycle_with')) ? "" : jade_interp) + "</span></a></li></ul>");;return buf.join("");
};

this["JST"]["views/templates/typeahead-fulltext"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),isEmpty = locals_.isEmpty,query = locals_.query,t = locals_.t;
buf.push("<!-- context will contain query and isEmpty.-->");
if (!( isEmpty))
{
buf.push("<div class=\"typeahead-suggestion fulltext\"><a href=\"#\"><div class=\"icon\"><span class=\"icon-icon-search\"></span></div>" + (null == (jade_interp = query + ' &mdash; ' + t('sidebar.search_fulltext')) ? "" : jade_interp) + "</a></div>");
};return buf.join("");
};

this["JST"]["views/templates/typeahead-no-results"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,query = locals_.query;
buf.push("<div class=\"typeahead-suggestion\"><p>" + (jade.escape(null == (jade_interp = t('sidebar.no_search_results') + ' "' + query + '"') ? "" : jade_interp)) + "</p></div>");;return buf.join("");
};

this["JST"]["views/templates/typeahead-suggestion"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),object_type = locals_.object_type,rootId = locals_.rootId,root_services = locals_.root_services,address = locals_.address,tAttr = locals_.tAttr,name = locals_.name,humanDateRange = locals_.humanDateRange,start_time = locals_.start_time,end_time = locals_.end_time;
var classes = object_type
buf.push("<div" + (jade.cls(['typeahead-suggestion',classes], [null,false])) + "><a href=\"#\"><div class=\"icon\">");
if ( object_type === 'service')
{
buf.push("<span class=\"icon-icon-browse\"></span>");
}
else if ( object_type === 'address')
{
buf.push("<span class=\"icon-icon-address\"></span>");
}
else if ( object_type === 'event')
{
buf.push("<span class=\"icon-icon-events\"></span>");
}
else if ( object_type === 'unit')
{
rootId = root_services.length ? root_services[0] : 0
buf.push("<div" + (jade.cls(["color-ball service-background-color-" + (rootId) + ""], [true])) + "></div>");
}
buf.push("</div><div class=\"suggestion-text\">");
if ( address)
{
buf.push(jade.escape(null == (jade_interp = address) ? "" : jade_interp));
}
else
{
buf.push(jade.escape(null == (jade_interp = tAttr(name)) ? "" : jade_interp));
}
buf.push("</div>");
if ( object_type === 'event')
{
var dates = humanDateRange(start_time, end_time)
buf.push("<div class=\"date\">" + (null == (jade_interp = dates[0]) ? "" : jade_interp));
if ( dates[1])
{
buf.push("&mdash;" + (null == (jade_interp = dates[1]) ? "" : jade_interp));
}
buf.push("</div>");
}
buf.push("</a></div>");;return buf.join("");
};

this["JST"]["views/templates/unit-accessibility-details"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),details = locals_.details,header_classes = locals_.header_classes,icon_class = locals_.icon_class,t = locals_.t,short_text = locals_.short_text,collapse_classes = locals_.collapse_classes,shortcomings_pending = locals_.shortcomings_pending,profile_set = locals_.profile_set,has_data = locals_.has_data,groups = locals_.groups,shortcomings_count = locals_.shortcomings_count,shortcomings = locals_.shortcomings,tAttr = locals_.tAttr,sentence_error = locals_.sentence_error,feedback = locals_.feedback;
jade_mixins["shortcomings"] = function(groups){
var block = (this && this.block), attributes = (this && this.attributes) || {};
buf.push("<dl>");
// iterate groups
;(function(){
  var $$obj = groups;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var group = $$obj[$index];

buf.push("<dt>" + (jade.escape(null == (jade_interp = group) ? "" : jade_interp)) + "</dt><dd><ul>");
// iterate details[group]
;(function(){
  var $$obj = details[group];
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var detail = $$obj[$index];

buf.push("<li>" + (jade.escape(null == (jade_interp = detail) ? "" : jade_interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var detail = $$obj[$index];

buf.push("<li>" + (jade.escape(null == (jade_interp = detail) ? "" : jade_interp)) + "</li>");
    }

  }
}).call(this);

buf.push("</ul></dd>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var group = $$obj[$index];

buf.push("<dt>" + (jade.escape(null == (jade_interp = group) ? "" : jade_interp)) + "</dt><dd><ul>");
// iterate details[group]
;(function(){
  var $$obj = details[group];
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var detail = $$obj[$index];

buf.push("<li>" + (jade.escape(null == (jade_interp = detail) ? "" : jade_interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var detail = $$obj[$index];

buf.push("<li>" + (jade.escape(null == (jade_interp = detail) ? "" : jade_interp)) + "</li>");
    }

  }
}).call(this);

buf.push("</ul></dd>");
    }

  }
}).call(this);

buf.push("</dl>");
};
buf.push("<a id=\"accessibility-collapser\" data-toggle=\"collapse\" data-parent=\"#details-view-container\" href=\"#accessibility-details\"" + (jade.cls(['collapsed','collapser',"" + (header_classes) + ""], [null,null,true])) + "><h3><span" + (jade.cls([icon_class], [false])) + ">&nbsp;</span>" + (jade.escape(null == (jade_interp = t('accessibility.accessibility')) ? "" : jade_interp)) + "</h3><span class=\"short-text\">" + (jade.escape(null == (jade_interp = short_text) ? "" : jade_interp)) + "</span></a><div id=\"accessibility-details\"" + (jade.cls(['section-content','collapse',"" + (collapse_classes) + ""], [null,null,true])) + ">");
if ( shortcomings_pending)
{
buf.push("<p>" + (jade.escape(null == (jade_interp = t('accessibility.pending_explanation')) ? "" : jade_interp)) + "</p>");
}
else
{
if ( !profile_set && has_data)
{
buf.push("<a href=\"#\" class=\"set-accessibility-profile prominent\">" + (jade.escape(null == (jade_interp = t('accessibility.select_accessibility_profile')) ? "" : jade_interp)) + "</a>");
}
if ( (!has_data && (!groups || groups.length == 0)))
{
buf.push("<div class=\"no-data-text\">" + (jade.escape(null == (jade_interp = t('accessibility.no_data_long')) ? "" : jade_interp)) + "</div>");
}
if ( profile_set)
{
var orderedSegments = ['outside', 'route_to_entrance', 'entrance', 'interior']
if ( shortcomings_count)
{
buf.push("<dl class=\"shortcomings\">");
// iterate orderedSegments
;(function(){
  var $$obj = orderedSegments;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var segment = $$obj[$index];

if ( shortcomings[segment])
{
var group = shortcomings[segment]
buf.push("<dt>" + (jade.escape(null == (jade_interp = t("accessibility.segment." + segment)) ? "" : jade_interp)) + "</dt><dd><ul>");
// iterate group
;(function(){
  var $$obj = group;
  if ('number' == typeof $$obj.length) {

    for (var requirementId = 0, $$l = $$obj.length; requirementId < $$l; requirementId++) {
      var messages = $$obj[requirementId];

buf.push("<li>");
// iterate messages
;(function(){
  var $$obj = messages;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  }
}).call(this);

buf.push("</li>");
    }

  } else {
    var $$l = 0;
    for (var requirementId in $$obj) {
      $$l++;      var messages = $$obj[requirementId];

buf.push("<li>");
// iterate messages
;(function(){
  var $$obj = messages;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  }
}).call(this);

buf.push("</li>");
    }

  }
}).call(this);

buf.push("</ul></dd>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var segment = $$obj[$index];

if ( shortcomings[segment])
{
var group = shortcomings[segment]
buf.push("<dt>" + (jade.escape(null == (jade_interp = t("accessibility.segment." + segment)) ? "" : jade_interp)) + "</dt><dd><ul>");
// iterate group
;(function(){
  var $$obj = group;
  if ('number' == typeof $$obj.length) {

    for (var requirementId = 0, $$l = $$obj.length; requirementId < $$l; requirementId++) {
      var messages = $$obj[requirementId];

buf.push("<li>");
// iterate messages
;(function(){
  var $$obj = messages;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  }
}).call(this);

buf.push("</li>");
    }

  } else {
    var $$l = 0;
    for (var requirementId in $$obj) {
      $$l++;      var messages = $$obj[requirementId];

buf.push("<li>");
// iterate messages
;(function(){
  var $$obj = messages;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var message = $$obj[index];

buf.push("<span>" + (jade.escape(null == (jade_interp = tAttr(message)) ? "" : jade_interp)) + "</span><br/>");
    }

  }
}).call(this);

buf.push("</li>");
    }

  }
}).call(this);

buf.push("</ul></dd>");
}
    }

  }
}).call(this);

buf.push("</dl>");
}
else if ( has_data)
{
buf.push("<div class=\"no-shortcomings-text\">" + (jade.escape(null == (jade_interp = t('accessibility.no_shortcomings_long')) ? "" : jade_interp)) + "</div>");
}
buf.push("<div class=\"accessibility-viewpoint\"></div>");
}
if ( !sentence_error)
{
if ( groups.length)
{
if ( profile_set && has_data)
{
buf.push("<a data-toggle=\"collapse\" data-parent=\"#accessibility-details\" href=\"#more-accessibility-details\" class=\"collapser collapsed sub-collapser\"><h4>" + (jade.escape(null == (jade_interp = t('accessibility.accessibility_details')) ? "" : jade_interp)) + "</h4><div id=\"more-accessibility-details\" class=\"collapse\">");
jade_mixins["shortcomings"](groups);
buf.push("</div></a>");
}
else
{
buf.push("<div id=\"more-accessibility-details\">");
jade_mixins["shortcomings"](groups);
buf.push("</div>");
}
}
else
{
if ( has_data)
{
buf.push("<div class=\"icon fa fa-spinner fa-spin\"></div>");
}
}
}
else
{
buf.push("<p>" + (jade.escape(null == (jade_interp = t('accessibility.error')) ? "" : jade_interp)) + "</p>");
}
buf.push("<a data-toggle=\"collapse\" data-parent=\"#accessibility-details\" href=\"#accessibility-feedback\" class=\"collapser hide collapsed sub-collapser\"><h4><span class=\"icon-icon-feedback\"></span>" + (jade.escape(null == (jade_interp = t('accessibility.feedback_on_accessibility')) ? "" : jade_interp)) + "</h4><span class=\"short-text\">");
if ( feedback.length)
{
buf.push((jade.escape(null == (jade_interp = feedback.length) ? "" : jade_interp)) + "&nbsp;" + (jade.escape(null == (jade_interp = t('accessibility.pcs')) ? "" : jade_interp)));
}
else
{
buf.push(jade.escape(null == (jade_interp = t('accessibility.none')) ? "" : jade_interp));
}
buf.push("</span></a><div id=\"accessibility-feedback\" class=\"collapse hide\">");
// iterate feedback
;(function(){
  var $$obj = feedback;
  if ('number' == typeof $$obj.length) {

    for (var index = 0, $$l = $$obj.length; index < $$l; index++) {
      var piece = $$obj[index];

buf.push("<a data-toggle=\"collapse\" data-parent=\"#accessibility-feedback\"" + (jade.attr("href", "#piece-" + (index) + "-content", true, false)) + " class=\"collapser collapsed sub-collapser\">" + (jade.escape(null == (jade_interp = piece.header) ? "" : jade_interp)) + "<span class=\"time\">" + (jade.escape(null == (jade_interp = ' (' + piece.time + ')') ? "" : jade_interp)) + "</span></a><div" + (jade.attr("id", "piece-" + (index) + "-content", true, false)) + " class=\"piece-content collapse\"><div class=\"content\">" + (jade.escape(null == (jade_interp = piece.content) ? "" : jade_interp)) + "</div><div class=\"author\">Left by a &nbsp;" + (jade.escape(null == (jade_interp = piece.profile) ? "" : jade_interp)) + "</div></div>");
    }

  } else {
    var $$l = 0;
    for (var index in $$obj) {
      $$l++;      var piece = $$obj[index];

buf.push("<a data-toggle=\"collapse\" data-parent=\"#accessibility-feedback\"" + (jade.attr("href", "#piece-" + (index) + "-content", true, false)) + " class=\"collapser collapsed sub-collapser\">" + (jade.escape(null == (jade_interp = piece.header) ? "" : jade_interp)) + "<span class=\"time\">" + (jade.escape(null == (jade_interp = ' (' + piece.time + ')') ? "" : jade_interp)) + "</span></a><div" + (jade.attr("id", "piece-" + (index) + "-content", true, false)) + " class=\"piece-content collapse\"><div class=\"content\">" + (jade.escape(null == (jade_interp = piece.content) ? "" : jade_interp)) + "</div><div class=\"author\">Left by a &nbsp;" + (jade.escape(null == (jade_interp = piece.profile) ? "" : jade_interp)) + "</div></div>");
    }

  }
}).call(this);

buf.push("</div><a href=\"#\" class=\"leave-feedback hide blue-link\">" + (jade.escape(null == (jade_interp = t('accessibility.leave_feedback')) ? "" : jade_interp)) + "</a><h4 class=\"hide\">" + (jade.escape(null == (jade_interp = t('accessibility.accessibility_contacts')) ? "" : jade_interp)) + "</h4><contacts class=\"hide\"><a href=\"#\" class=\"phone external-link\">09 123 1234 &nbsp;</a><a href=\"#\" class=\"email external-link\">" + (jade.escape(null == (jade_interp = t('accessibility.send_email')) ? "" : jade_interp)) + "</a></contacts>");
}
buf.push("</div>");;return buf.join("");
};

this["JST"]["views/templates/unit-list-item"] = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),t = locals_.t,area = locals_.area,name = locals_.name,emergencyUnitId = locals_.emergencyUnitId;
buf.push("<a href=\"#\" class=\"unit\"><div class=\"service-type\">" + (jade.escape(null == (jade_interp = t('position.service_type.' + area.get('type'))) ? "" : jade_interp)) + "</div><div class=\"title\">" + (jade.escape(null == (jade_interp = name) ? "" : jade_interp)) + "</div>");
if ( emergencyUnitId)
{
buf.push("<div class=\"emergency-unit-notice\">" + (null == (jade_interp = t('position.emergency_care.common', {children: t('position.emergency_care.children')})) ? "" : jade_interp) + " <a" + (jade.attr("href", "/unit/" + emergencyUnitId, true, false)) + " class=\"blue-link\">" + (null == (jade_interp = t('position.emergency_care.unit.' + emergencyUnitId)) ? "" : jade_interp) + "</a> " + (null == (jade_interp = t('position.emergency_care.link')) ? "" : jade_interp) + "</div>");
}
buf.push("</a>");;return buf.join("");
};