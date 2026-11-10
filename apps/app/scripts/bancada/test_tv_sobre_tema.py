"""O item Tema não pode fazer a bancada confundir Ajustes com Sobre."""
import unittest
from unittest.mock import patch

import tv


def linha_focada(titulo):
    return [{'focused': True, 'desc': titulo, 'bounds': [48, 123, 1872, 243], 'cls': 'android.view.View'}]


SOBRE = [{'text': 'Nada entre você e o filme.'}, {'text': 'Dicas do Heisuca'}]


class SobreComTemaTest(unittest.TestCase):
    def test_alcanca_sobre_por_rotulo_depois_da_linha_tema(self):
        linhas = ['Perfil', 'Tema', 'Áudio padrão', 'Legenda padrão', 'Tamanho da legenda',
                  'Ainda está aí?', 'Desempenho na tela', 'Sobre\nHeisuca\nVer']
        with patch.object(tv, 'dump_tv', side_effect=[*[linha_focada(t) for t in linhas], SOBRE]), \
                patch.object(tv, 'dpad_down') as descer, patch.object(tv, 'dpad_center') as confirmar:
            self.assertTrue(tv.abrir_sobre_tv())
        self.assertEqual(descer.call_count, 7)
        confirmar.assert_called_once()

    def test_nao_confirma_outro_ajuste_quando_sobre_nao_recebe_foco(self):
        with patch.object(tv, 'dump_tv', return_value=linha_focada('Ainda está aí?')), \
                patch.object(tv, 'dpad_down'), patch.object(tv, 'dpad_center') as confirmar:
            self.assertFalse(tv.abrir_sobre_tv(max_passos=2))
        confirmar.assert_not_called()

    def test_nao_aprova_ajustes_com_sobre_visivel_mas_sem_abrir_a_pagina(self):
        ajustes = linha_focada('Ainda está aí?\nDesligado') + [{'text': 'Sobre'}, {'text': 'Ajustes'}]
        with patch.object(tv, 'dump_tv', side_effect=[linha_focada('Sobre\nVer'), ajustes]), \
                patch.object(tv, 'dpad_center'), patch.object(tv, 'dpad_down') as descer:
            self.assertFalse(tv.abrir_sobre_tv())
        descer.assert_not_called()
