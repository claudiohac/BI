create or replace view bi_receitaPrevista as
--Abaixo os lançamentos normais (sem anulação). Claudio 07/04/2016
select rec.exercicio                                            as numExercicio,
       uniorc.codigo_orgao                                      as codOrgao,
       uniorc.codigo_unidade_orcamentaria                       as codUnidOrc,
       uniorc.orgao_siof                                        as codOrgaoSIOF,
       substr(fonte.codigo_completo_fonte_recurso,1,1)          as codIndicadorUso,
       case when rec.exercicio < 2016 
           then substr(fonte.codigo_completo_fonte_recurso,2,1) 
           else substr(fonte.codigo_completo_fonte_recurso,2,2) 
       end                                                      as codTpFonte, --Alterado, >= 2016 está pegando o grupo fonte para cá.Claudio
       case when rec.exercicio < 2016 
         then substr(fonte.codigo_completo_fonte_recurso,3,2) 
         else substr(fonte.codigo_completo_fonte_recurso,4,2) 
       end                                                      as CodFonte, --Alterado, >= 2016 está pegando o sub grupo fonte para cá.Claudio
       rec.codigo_receita                                       as codGeralNatReceita,
       nvl(sum(fn_ret_vlr_receita2016(rec.exercicio,
                                      rec.codigo_receita,
                                      rec.categoria_economica,
                                      1,
                                      prf.valor_fonte)),0)      as valReceitaPrevista
from previsao_receita_fonte prf
join previsao_receita       prev  on prev.id_previsao_receita       = prf.id_previsao_receita
join receita_contabil_orc    rec  on rec.id_receita_contabil_orc    = prev.receita_orc
join unidade_orcamentaria uniorc  on uniorc.id_unidade_orcamentaria = prev.unidade_orcamentaria
join fonte_recurso         fonte  on fonte.id_fonte_recurso         = prf.id_fonte_recurso
where 1=1
  and 2=2
  and (prf.valor_fonte > 0 and prf.valor_fonte is not null)
group by rec.exercicio,
         uniorc.orgao_siof,
         uniorc.codigo_orgao,
         uniorc.codigo_unidade_orcamentaria,
         rec.codigo_receita,
         fonte.codigo_completo_fonte_recurso
order by rec.exercicio,
         uniorc.codigo_orgao,
         uniorc.codigo_unidade_orcamentaria,
         rec.codigo_receita,
         fonte.codigo_completo_fonte_recurso
