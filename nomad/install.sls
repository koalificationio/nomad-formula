# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "nomad/map.jinja" import nomad with context %}

nomad-bin-dir:
  file.directory:
   - name: {{ nomad.bin_dir }}
   - makedirs: True

nomad-config-dir:
  file.directory:
    - name: {{ nomad.config_dir }}
    - makedirs: True

nomad-data-dir:
  file.directory:
    - name: {{ nomad.config.data_dir }}
    - makedirs: True

nomad-install-binary:
  archive.extracted:
    - name: {{ nomad.bin_dir }}
    - source: https://releases.hashicorp.com/nomad/{{ nomad.version }}/nomad_{{ nomad.version }}_{{ grains['kernel'] | lower }}_{{ nomad.arch }}.zip
    - source_hash: https://releases.hashicorp.com/nomad/{{ nomad.version }}/nomad_{{ nomad.version }}_SHA256SUMS
    # If we don't force it here, the mere presence of an older version will prevent an upgrade.
    - overwrite: True
    # Hashicorp gives a zip with a single binary. Salt doesn't like that.
    - enforce_toplevel: False
    - require:
      - service: nomad-install-binary
    - unless:
      - '{{ nomad.bin_dir }}/nomad -v && {{ nomad.bin_dir }}/nomad -v | grep {{ nomad.version }}'
  file.managed:
    - name: {{ nomad.bin_dir }}/nomad
    - user: root
    - group: root
    - mode: 0755
    - require:
      - archive: nomad-install-binary
  service.dead:
    - name: nomad
    - unless:
      - '{{ nomad.bin_dir }}/nomad -v && {{ nomad.bin_dir }}/nomad -v | grep {{ nomad.version }}'

nomad-install-service:
  file.managed:
    - name: /etc/systemd/system/nomad.service
    - source: https://raw.githubusercontent.com/hashicorp/nomad/v{{ nomad.version }}/dist/systemd/nomad.service
    - source_hash: {{ nomad.service_hash }}
    - onchanges:
      - nomad-install-binary
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: nomad-install-service

