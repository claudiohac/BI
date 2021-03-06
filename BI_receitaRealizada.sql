ALTER SESSION SET CURRENT_SCHEMA=GRPFOR_FC;

create or replace view bi_receitarealizada as
select rec.exercicio                                                                   as numExercicio,
       uniorc.orgao_siof                                                               as codOrgaoSIOF,
       uniorc.codigo_orgao                                                             as codOrgao,
       uniorc.codigo_unidade_orcamentaria                                              as codUnidOrc,
       movrec.data_caixa                                                               as datLancamento,
       case when rec.exercicio < 2019
             then fonte.codigo_completo_fonte_recurso
       else -- somente para 2019 pra frente, fonte nova
         case when dpara.codigo_fonte is null 
           then fonte.codigo_completo_fonte_recurso                                                         
           else substr(fonte.codigo_completo_fonte_recurso,1,1) || dpara.codigo_fonte
         end                                                                                         
       end                                                                             as codigo_completo,
       substr(fonte.codigo_completo_fonte_recurso,1,1)                                 as codIndicadorUso,
       case when rec.exercicio < 2016                           
              then substr(fonte.codigo_completo_fonte_recurso,2,1) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,2,2) 
              else case when dpara.codigo_fonte is null 
                     then substr(fonte.codigo_completo_fonte_recurso,2,10)
                     else substr(dpara.codigo_fonte,1,10)                  --alterado para verificar o de-para da fonte a partir de 2019
                   end
       end                                                                             as codTpFonte, --Alterado em 05/04/2016, >= 2016 est? pegando o grupo fonte para c?.Claudio
       case when rec.exercicio <  2016                          
              then substr(fonte.codigo_completo_fonte_recurso,3,2) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,4,2)
              else case when dpara.codigo_fonte is null 
                     then substr(fonte.codigo_completo_fonte_recurso,12,2) 
                     else substr(dpara.codigo_fonte,11,2)                  --alterado para verificar o de-para da fonte a partir de 2019
                   end
       end                                                                             as CodFonte, --Alterado em 05/04/2016, >= 2016 est? pegando o sub grupo fonte para c?.Claudio
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
left join depara_fonte_recurso  dpara on dpara.id_fonte_recurso         = movrec.fonte_recurso
where movrec.data_caixa is not null
  and movrec.tipo_operacao not in (2,4,6,8) --retirando as anula??es.Claudio 05/04/2016
group by rec.exercicio,
         uniorc.orgao_siof,
         uniorc.codigo_orgao,
         uniorc.codigo_unidade_orcamentaria,
         movrec.data_caixa,
         rec.codigo_receita,
         fonte.codigo_completo_fonte_recurso,
         dpara.codigo_fonte

union all

--Abaixo os lan?amentos de anula??o sem os novos c?digos de anula??o de 2016 (92 e 98). Claudio 05/04/2016
select rec.exercicio                                                                    as numExercicio,
       uniorc.orgao_siof                                                                as codOrgaoSIOF,
       uniorc.codigo_orgao                                                              as codOrgao,
       uniorc.codigo_unidade_orcamentaria                                               as codUnidOrc,
       movrec.data_caixa                                                                as datLancamento,
       case when rec.exercicio < 2019
         then fonte.codigo_completo_fonte_recurso
       else -- somente para 2019 pra frente, fonte nova
         case when dpara.codigo_fonte is null 
                then fonte.codigo_completo_fonte_recurso                                                         
                else substr(fonte.codigo_completo_fonte_recurso,1,1) || dpara.codigo_fonte
         end                                                                                         
       end                                                                              as codigo_completo,
       substr(fonte.codigo_completo_fonte_recurso,1,1)                                  as codIndicadorUso,
       
       case when rec.exercicio < 2016                           
              then substr(fonte.codigo_completo_fonte_recurso,2,1) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,2,2) 
              else case when dpara.codigo_fonte is null 
                     then substr(fonte.codigo_completo_fonte_recurso,2,10)
                     else substr(dpara.codigo_fonte,1,10)                  --alterado para verificar o de-para da fonte a partir de 2019
                   end
       end                                                                              as codTpFonte, --Alterado em 05/04/2016, >= 2016 est? pegando o grupo fonte para c?.Claudio
       case when rec.exercicio < 2016                           
              then substr(fonte.codigo_completo_fonte_recurso,3,2) 
            when rec.exercicio >= 2016 and rec.exercicio < 2019 
              then substr(fonte.codigo_completo_fonte_recurso,4,2) 
              else case when dpara.codigo_fonte is null 
                     then substr(fonte.codigo_completo_fonte_recurso,12,2)
                     else substr(dpara.codigo_fonte,11,2)                  --alterado para verificar o de-para da fonte a partir de 2019
                   end
       end                                                                              as CodFonte, --Alterado em 05/04/2016, >= 2016 est? pegando o sub grupo fonte para c?.Claudio
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
left join depara_fonte_recurso  dpara on dpara.id_fonte_recurso         = movrec.fonte_recurso
where movrec.data_caixa is not null
  and movrec.tipo_operacao in (2,4,6,8) --filtrando apenas as anula??es.Claudio 05/04/2016
group by rec.exercicio,
         uniorc.orgao_siof,
         uniorc.codigo_orgao,
         uniorc.codigo_unidade_orcamentaria,
         movrec.data_caixa,
         rec.codigo_receita,
         fonte.codigo_completo_fonte_recurso,
         dpara.codigo_fonte;

