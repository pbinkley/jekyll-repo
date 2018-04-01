---
layout: default
---

<h1>Creators</h1>

{% assign creators = site.data['creators'] %}

<h2>Table of Contents</h2>
<ul class="toc">
{% for creator in creators %}
  {% capture slug %}{{ creator[0] | slugify }}{% endcapture %}
  <li><a href="#{{ slug }}">{{ creator[0] }}</a> 
  ({{ creator[1] | size }})</li>
{% endfor %}  
</ul>

{% for creator in creators %}
  {% capture slug %}{{ creator[0] | slugify }}{% endcapture %}
  <h2 id="{{ slug }}">{{ creator[0] }}<h2>
  <ul class="docs">
    {% assign docs = creator[1] | sort: 'pdfname' %}
    {% for doc in docs %}
      {% include document.html doc=doc %}
    {% endfor %}
  </ul>
{% endfor %}
