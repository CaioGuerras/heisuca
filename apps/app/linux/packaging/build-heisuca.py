#!/usr/bin/env python3
"""Package the verified Linux bundle; derive host dependencies from its ELF files."""
import argparse, hashlib, importlib.util, os, pathlib, re, shutil, subprocess, tarfile
root=pathlib.Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--bundle',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,default=root/'dist/linux');a=p.parse_args()
bundle=a.bundle.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
assert (bundle/'heisuca').is_file(),'Missing compiled Heisuca'
os.environ['APP_BINARY']='heisuca'
spec=importlib.util.spec_from_file_location('hostdeps',root/'linux/packaging/check-bundle-host-deps.py');guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard)
needed,errors=guard.host_libraries(bundle)
if errors:raise RuntimeError('\n'.join(errors))
assert needed,'Host dependency scan returned no libraries'
deps=set()
for soname,path in needed.items():
 owner=guard.deb_owner(path)
 if not owner:raise RuntimeError('Unowned host library: '+soname)
 deps.add(owner)
libc=subprocess.check_output(['getconf','GNU_LIBC_VERSION'],text=True).split()[-1];deps.add('libc6 (>= '+libc+')')
version=re.search(r'^version:\s*([^+\s]+)',(root/'pubspec.yaml').read_text(),re.M).group(1)
stage=out/'staging';assert not stage.exists(),'Use a fresh output directory'
app=stage/'opt/heisuca';app.parent.mkdir(parents=True);shutil.copytree(bundle,app,symlinks=True)
(app/'heisuca').rename(app/'heisuca-bin')
wrapper=(root/'linux/packaging/plezy.sh').read_text().replace('/opt/plezy','/opt/heisuca').replace('"$INSTALL_DIR/plezy"','"$INSTALL_DIR/heisuca-bin"')
(app/'heisuca').write_text(wrapper);(app/'heisuca').chmod(0o755)
(app/'LEIA-ME.txt').write_text('Heisuca Linux x64 — versão de teste\nUbuntu24.04+ com sessão Wayland nativa. X11 não reproduz vídeo nesta versão.\nExtraia todo o arquivo e execute ./heisuca. Os dados ficam no perfil do usuário.\nConexões protegidas pelo cofre do sistema (SecretService); sem serviço disponível, a sessão é temporária e o app avisa.\nDependências do sistema: '+', '.join(sorted(deps))+'\nSem certificação de GPU/áudio físicos. https://heisuca.docaio.com.br/\n')
license_file=root/'assets/heisuca/LICENCA_GPL_3.txt';shutil.copy2(license_file,app/'LICENSE.txt')
applications=stage/'usr/share/applications';applications.mkdir(parents=True);shutil.copy2(root/'linux/packaging/app.heisuca.player.desktop.desktop',applications/'app.heisuca.player.desktop.desktop')
icons=stage/'usr/share/icons/hicolor/scalable/apps';icons.mkdir(parents=True);shutil.copy2(root/'assets/heisuca/icone_shikkoku_cheio.svg',icons/'heisuca.svg')
bin_dir=stage/'usr/bin';bin_dir.mkdir(parents=True);(bin_dir/'heisuca').symlink_to('/opt/heisuca/heisuca')
control=stage/'DEBIAN';control.mkdir();(control/'control').write_text('Package: heisuca\nVersion: '+version+'\nArchitecture: amd64\nMaintainer: Heisuca <noreply@github.com>\nSection: video\nPriority: optional\nHomepage: https://heisuca.docaio.com.br/\nDepends: '+', '.join(sorted(deps))+'\nRecommends: gnome-keyring\nDescription: Heisuca — player Plex/Jellyfin para Linux com Wayland\n')
for directory,_,files in os.walk(stage):
 pathlib.Path(directory).chmod(0o755)
 for name in files:
  f=pathlib.Path(directory)/name
  if not f.is_symlink():f.chmod(0o755 if os.access(f,os.X_OK) else 0o644)
subprocess.run(['dpkg-deb','--build','--root-owner-group',str(stage),str(out/'heisuca-linux-x64.deb')],check=True)
with tarfile.open(out/'heisuca-linux-x64.tar.gz','w:gz') as t:t.add(app,arcname='heisuca')
for file in [out/'heisuca-linux-x64.deb',out/'heisuca-linux-x64.tar.gz']:
 digest=hashlib.sha256(file.read_bytes()).hexdigest();file.with_suffix(file.suffix+'.sha256').write_text(digest+'  '+file.name+'\n');print(file.name,file.stat().st_size,digest)
(out/'host-dependencies.txt').write_text('\n'.join(sorted(deps))+'\n')
