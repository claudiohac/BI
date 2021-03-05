ALTER SESSION SET CURRENT_SCHEMA=GRPFOR_FC;

create or replace view bi_receitarealizada_contates as
select rec.exercicio                                                                   as numExercicio,
       uniorc.orgao_siof                                                               as codOrgaoSIOF,
       uniorc.codigo_orgao                                                             as codOrgao,
       uniorc.codigo_unidade_orcamentaria                                              as codUnidOrc,
       movrec.data_caixa                                                               as datLancamento,
       fonte.codigo_completo_fonte_recurso                                             as codigo_completo,
       substr(fonte.codigo_completo_fonte_recurso,1,1)                                 as codIndicadorUso,
       ctates.num_conta_tesouraria                                                     as contaTesouraria,
       
       --Regras para o tratamento de fonte (Tipo de fonte) no decorrer dos exercícios. Cláudio 04/02/2019
       case when rec.exercicio < 2016                           
              then substr(fonte.codigo_completo_fonte_recurso,2,1) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,2,2) 
              else case when fonte.exercicio >= 2019                                    -- O exercicio da fonte é menor que 2019, então fica com a regra antiga. Claudio 01/02/2019
                     then substr(fonte.codigo_completo_fonte_recurso,2,10)
                     else substr(fonte.codigo_completo_fonte_recurso,2,2)
                   end
       end                                                                             as codTpFonte, --Alterado em 05/04/2016, >= 2016 está pegando o grupo fonte para cá.Claudio

       --Regras para o tratamento de fonte (Código fonte) no decorrer dos exercícios. Cláudio 04/02/2019
       case when rec.exercicio <  2016                          
              then substr(fonte.codigo_completo_fonte_recurso,3,2) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,4,2)
              else case when fonte.exercicio >= 2019                                    -- O exercicio da fonte é menor que 2019, então fica com a regra antiga. Claudio 01/02/2019
                     then substr(fonte.codigo_completo_fonte_recurso,12,2)
                     else substr(fonte.codigo_completo_fonte_recurso,4,2)
                   end
       end                                                                             as CodFonte, --Alterado em 05/04/2016, >= 2016 está pegando o sub grupo fonte para cá.Claudio
       case when substr(rec.codigo_receita,1,2) in (98,92) 
         then substr(rec.codigo_receita,3,10) 
         else rec.codigo_receita 
       end                                                                             as codGeralNatReceita,
       nvl(sum(fn_ret_vlr_receita2016(rec.exercicio,
                                      rec.codigo_receita,
                                      rec.categoria_economica,
                                      movrec.tipo_operacao,
                                      movrec.valor)),0)                                as valReceitaRealizada
from movimentacao_receita movrec
     join receita_contabil_orc    rec on rec.id_receita_contabil_orc    = movrec.codigo_receita
     join unidade_orcamentaria uniorc on uniorc.id_unidade_orcamentaria = movrec.unidade_orcamentaria
     join fonte_recurso        fonte  on fonte.id_fonte_recurso         = movrec.fonte_recurso
     join conta_tesouraria     ctates on ctates.id_conta_tesouraria     = movrec.conta_tesouraria
where movrec.data_caixa is not null
  and movrec.tipo_operacao not in (2,4,6,8) --retirando as anulações.Claudio 05/04/2016
  --and movrec.data_caixa between '01/01/2019' and '31/12/2019'
group by rec.exercicio,
         uniorc.orgao_siof,
         uniorc.codigo_orgao,
         uniorc.codigo_unidade_orcamentaria,
         movrec.data_caixa,
         rec.codigo_receita,
         fonte.codigo_completo_fonte_recurso,
         fonte.exercicio,
         ctates.num_conta_tesouraria

union all

--Abaixo os lançamentos de anulação sem os novos códigos de anulação de 2016 (92 e 98). Claudio 05/04/2016
select rec.exercicio                                                                    as numExercicio,
       uniorc.orgao_siof                                                                as codOrgaoSIOF,
       uniorc.codigo_orgao                                                              as codOrgao,
       uniorc.codigo_unidade_orcamentaria                                               as codUnidOrc,
       movrec.data_caixa                                                                as datLancamento,
       fonte.codigo_completo_fonte_recurso                                              as codigo_completo,
       substr(fonte.codigo_completo_fonte_recurso,1,1)                                  as codIndicadorUso,
       ctates.num_conta_tesouraria                                                      as contaTesouraria,

       --Regras para o tratamento de fonte (Tipo de fonte) no decorrer dos exercícios. Cláudio 04/02/2019
       case when rec.exercicio < 2016                           
              then substr(fonte.codigo_completo_fonte_recurso,2,1) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,2,2) 
              else case when fonte.exercicio >= 2019                                    -- O exercicio da fonte é menor que 2019, então fica com a regra antiga. Claudio 01/02/2019
                     then substr(fonte.codigo_completo_fonte_recurso,2,10)
                     else substr(fonte.codigo_completo_fonte_recurso,2,2)
                   end
       end                                                                              as codTpFonte, --Alterado em 05/04/2016, >= 2016 está pegando o grupo fonte para cá.Claudio

       --Regras para o tratamento de fonte (Código fonte) no decorrer dos exercícios. Cláudio 04/02/2019
       case when rec.exercicio < 2016                           
              then substr(fonte.codigo_completo_fonte_recurso,3,2) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,4,2) 
              else case when fonte.exercicio >= 2019                                    -- O exercicio da fonte é menor que 2019, então fica com a regra antiga. Claudio 01/02/2019
                     then substr(fonte.codigo_completo_fonte_recurso,12,2)
                     else substr(fonte.codigo_completo_fonte_recurso,4,2)
                   end
       end                                                                              as CodFonte, --Alterado em 05/04/2016, >= 2016 está pegando o sub grupo fonte para cá.Claudio
       case 
         when rec.exercicio <= 2015
           then rec.codigo_receita
         when rec.exercicio = 2016
           then case when substr(rec.codigo_receita,1,2) = '95'  
                       then rec.codigo_receita 
                       else substr(rec.codigo_receita,3,8)
                end                                        
         when rec.exercicio >= 2017
           then case when substr(rec.codigo_receita,1,2) = '95'  
                       then rec.codigo_receita 
                       else substr(rec.codigo_receita,3,10)
                end               
       end                                                                              as codGeralNatReceita,
       nvl(sum(fn_ret_vlr_receita2016(rec.exercicio,rec.codigo_receita,rec.categoria_economica,movrec.tipo_operacao,movrec.valor)),0) as valReceitaRealizada
from movimentacao_receita movrec
     join receita_contabil_orc    rec on rec.id_receita_contabil_orc    = movrec.codigo_receita
     join unidade_orcamentaria uniorc on uniorc.id_unidade_orcamentaria = movrec.unidade_orcamentaria
     join fonte_recurso         fonte on fonte.id_fonte_recurso         = movrec.fonte_recurso
     join conta_tesouraria     ctates on ctates.id_conta_tesouraria     = movrec.conta_tesouraria
where movrec.data_caixa is not null
  and movrec.tipo_operacao in (2,4,6,8) --filtrando apenas as anulações.Claudio 05/04/2016
  --and movrec.data_caixa between '01/01/2019' and '31/12/2019'
group by rec.exercicio,
         uniorc.orgao_siof,
         uniorc.codigo_orgao,
         uniorc.codigo_unidade_orcamentaria,
         movrec.data_caixa,
         rec.codigo_receita,
         fonte.codigo_completo_fonte_recurso,
         fonte.exercicio,
         ctates.num_conta_tesouraria;

