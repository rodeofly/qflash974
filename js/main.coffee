THEMES = {}
ID=1

#console.log JSON.stringify THEMES

class CardSet
  constructor: (@theme, @cycle) ->
    @attendus = THEMES[@theme]['attendus']
    @set = []
    numero_attendu = 0
    nombre_attendus = Object.keys(@attendus).length
    $carte = $($("#carteObject").html())
    $recto = $carte.find(".recto")
    $verso = $carte.find(".verso")


    for attendu of @attendus
      numero_attendu++
      numero_notion = 0
      nombre_notions = Object.keys(THEMES[@theme]['attendus'][attendu]['notions']).length

      for notion, savoirfaires of THEMES[@theme]['attendus'][attendu]['notions']
        id = ID++
        numero_notion++
        domainClass = THEMES[@theme]['attendus'][attendu]['domaine']
        
        #recto de la carte
        $carte.find( ".bleeding.recto" ).attr "data-id", "#{id}r"
        $recto.attr "data-id", "#{id}r"
        $recto.attr "data-theme", THEMES[@theme]['classe']
        $recto.find(".carteID").html id
        $recto.find(".cycle").html @cycle
        $recto.find(".theme").html @theme
        $recto.find(".logo").attr "data-theme", THEMES[@theme]['classe']
        $recto.find(".attendu-title").html "[#{numero_attendu}/#{nombre_attendus}] #{attendu}"
        $recto.find(".attendu-title").attr "data-domaine", domainClass
        $recto.find(".citation").html THEMES[@theme]['citation']
        $recto.find(".notion").html notion
       
        
        # Mise en place des checkbox par notion d'attendu
        html = ""
        for n in [1..nombre_notions]
          if n is numero_notion
            html += "<img class='no-icon chkbox-checked'>"
          else
            html += "<img class='no-icon chkbox-unchecked'>"
        $recto.find(".notions-targets").html html
        
        #verso de la carte
        $carte.find( ".bleeding.verso" ).attr "data-id", "#{id}v"
        $verso.attr "data-theme", THEMES[@theme]['classe']
        $verso.attr "data-id", "#{id}v"
        #$verso.find(".carteID").html id
        $verso.find(".cycle").html "Correction"
        $verso.find(".theme").html @theme
        $verso.find(".logo").attr "data-theme", THEMES[@theme]['classe']
        
        
        a=0
        $verso.find( ".attendus-content" ).empty()
        for attenduV, notionsV of THEMES[@theme]['attendus']
          a++
          if a is numero_attendu
            #console.log attenduV
            $verso.find( ".attendus-content" ).append """
              <li class='attenduV'>
                #{attenduV}
                <ol class='notions'></ol>
              </li>
            """
            n = 0
            for notionV, savoirfairesV of notionsV.notions
              n++      
              if (n is numero_notion)
                $verso.find(".notions").append """
                <li class='notion'>#{notionV}
                  <ol class='savoirfaires'></ol>
                </li>"""
                for savoirfaire, niveau of savoirfairesV
                  $verso.find(".savoirfaires").append """
                    <li>#{savoirfaire}  
                      <img class='star' src='img/#{niveau}star.png'>
                    </li>"""
              else $verso.find(".notions").append "<li class='notion'>#{notionV}</li>"
          else $verso.find( ".attendus-content" ).append "<li class='attendu'>#{attenduV}</li>"

        
        
        carte = $("<div></div>")
        carte.append $carte
        @set.push carte.html()


$ ->
  zip = new JSZip()
  batkartQF = (file, cycle) ->
    $( ".QFquestion" ).each ->
      $( ".deck" ).hide()
      id = $(this).data("id")
      console.log $(this)
      card = id.split(".")[1]
      num_sf = id.split(".")[2]
      dtab= $(this).data("domaines")
      dcomp = $(this).data("competences")
      enonce = $(this).find( ".QFEnonce").contents()
      correction = $(this).find( ".QFCorrection").contents()     
     
      $refr = $( ".deck .face[data-id='#{card}r']")
      $refv = $( ".deck .face[data-id='#{card}v']")
      totalSF = $refv.find(".savoirfaires>li").length
      savoirfaire = $refv.find(".savoirfaires>li:nth-child(#{num_sf})").html()
      console.log savoirfaire
      $carte = ($refr.parent().parent().parent()).clone()
      $carte.find( ".savoirfaire" ).append  "n°#{num_sf}/#{totalSF} : #{savoirfaire}"
      for domaine in ["D1","D2","D3","D4","D5"]
        if domaine in dtab
          $carte.find( ".domaines" ).append  "<div class='domaine' data-domaine='#{domaine}'></div>"
      for competence in ["chercher","modeliser","representer","raisonner","calculer", "communiquer"]
        if competence in dcomp
          $carte.find( ".competences" ).append "<div class='competence #{competence}'></div>"
      $carte.find(".question").append enonce
      #$carte.find(".question").append "<img src='./img/QFlash974/#{qf}.E.png'>"
      $carte.find(".carteID").html ID
      $( ".deckQF" ).append $carte
      $carte = ($refv.parent().parent().parent()).clone()
      $carte.find(".correction").append correction 
      #$carte.find(".correction").append "<img src='./img/QFlash974/#{qf}.C.png'>"
      $( ".deckQF" ).append $carte
      ID++
            
        
      
  batkart = (file, cycle) ->
    $.getJSON file, ( data ) -> 
      THEMES = data
      themes = Object.keys(THEMES)
      $( ".deck" ).empty()
      for theme in themes
        set = new CardSet theme, cycle
        for s in set.set
          $( ".deck" ).append s     
      $(".deck").sortable()
      #$( ".verso" ).hide()

  generateCanvas = (UID, carte, id, zip, deferred) ->
    html2canvas( carte ).then (canvas) -> 
      imgUrl = canvas.toDataURL()
      zip.file("#{UID}.carte-#{id}.png", imgUrl.split('base64,')[1],{base64: true})
      deferred.resolve()
      $("#info").html "Carte #{id} ##{UID} traité !"
  
  $( "#toPNG" ).on "click", ->
    $(this).prop("disabled",true)
    deferreds = [];
    $selected_bleedings = $(".bleeding:visible")
    UID = 0
    $selected_bleedings.each ->
      UID++
      id = $(this).attr("data-id")
      $("#info").html "Envoi de la carte #{id}"
      deferred = $.Deferred()
      deferreds.push(deferred.promise())
      generateCanvas(UID,$(this)[0], id, zip, deferred)
    $("#info").html "Travail en cours..."
      
    $.when.apply($, deferreds).then () ->
      $( "#toPNG" ).prop("disabled",false)
      zip.generateAsync({ type: "blob" }).then (content) ->
        link = document.createElement('a')
        blobLink = window.URL.createObjectURL(content)
        link.addEventListener 'click', (ev) ->
          link.href = blobLink;
          link.download = 'cartes.zip'
        , false
        link.click()
  
  $( "#cycle3" ).on "click", -> 
    ID = 1
    batkart "cycle3.json", "Cycle 3"
  
  $( "#cycle4" ).on "click", -> 
    ID = 1
    batkart "cycle4.json", "Cycle 4" 
    
  $( "#toQF" ).on "click", -> 
    ID = 1
    batkartQF "QFcycle3.json", "Cycle 4" 

    
    
    
