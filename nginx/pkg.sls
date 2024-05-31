# nginx.pkg
#
# Manages installation of nginx from pkg.

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import nginx, sls_block with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

{%- if nginx.install_from_repo %}
  {% set from_official = true %}
  {% set from_ppa = false %}
  {% set from_phusionpassenger = false %}
  {% set from_opensuse_devel = false %}
{% else %}
  {% set from_official = false %}
  {% set from_ppa = false %}
  {% set from_phusionpassenger = false %}
  {% set from_opensuse_devel = false %}
{%- endif %}

{%- set resource_repo_managed = 'file' if grains.os_family == 'Debian' else 'pkgrepo' %}

nginx_install:
  pkg.installed:
    {{ sls_block(nginx.package.opts) }}
    {% if nginx.lookup.package is iterable and nginx.lookup.package is not string %}
    - pkgs:
      {% for pkg in nginx.lookup.package %}
      - {{ pkg }}
      {% endfor %}
    {% else %}
    - name: {{ nginx.lookup.package }}
    {% endif %}

{% if grains.os_family == 'Debian' %}
  {%- if from_official %}
nginx_official_repo_keyring:
  file.managed:
    - name: {{ nginx.lookup.package_repo_keyring }}
    - source: {{ files_switch(['nginx-archive-keyring.gpg'],
                              lookup='nginx_official_repo_keyring'
                 )
              }}
    - require_in:
      - {{ resource_repo_managed }}: nginx_official_repo

nginx_official_repo:
  file:
    {%- if from_official %}
    - managed
    {%- else %}
    - absent
    {%- endif %}
    - name: /etc/apt/sources.list.d/nginx-official-{{ grains.oscodename }}.list
    - contents: >
        deb [signed-by={{ nginx.lookup.package_repo_keyring }}]
        http://nginx.org/packages/{{ grains.os | lower }}/ {{ grains.oscodename }} nginx

    - require_in:
      - pkg: nginx_install
    - watch_in:
      - pkg: nginx_install
{%- endif %}
{%- endif %}
