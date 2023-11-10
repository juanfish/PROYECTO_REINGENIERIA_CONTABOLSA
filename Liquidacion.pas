unit Liquidacion;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, ToolEdit, sToolEdit, ComCtrls, ExtCtrls, sMaskEdit,
  sCustomComboEdit, sysvar, principal;

type
  Tfrmliquidacion = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Bevel1: TBevel;
    PB1: TProgressBar;
    TXTdesde: TsDateEdit;
    Label1: TLabel;
    st1: TStaticText;
    Label2: TLabel;
    txtasignacion: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    swLog : Boolean;
    logAsientosLiquida : TLogAsiento;
			{ Private declarations }
    procedure Graba_linea(cta, observa, ref: string; mto, tasa: double; debcre: boolean; observa1, observa2, origen, clave, ref2, ref3: string; num_corre: integer);
    procedure genera_reverso_derecho_cli(origen: string);
    procedure genera_reverso_derecho_bol(origen: string; nuconcepto: integer);
    function suma_dlia(desde: string; veces: integer; conferiado: boolean): string; //ces 18/02/2004
    procedure Genera_cmi_Cli;
    procedure AjustaCodigo(var _chara11, _chara12: string);
    procedure crealog(rutarchivo: string);
    function reemplazaAuxiliarContable(cuenta : string):string;
  public
			{ Public declarations }

  end;

var
  frmliquidacion: Tfrmliquidacion;
  efectivocli, efectivobolsa: double;
  posicionhoy, capitalhoy, precioprom: double;
  rutalog: string;

implementation

uses
  sysvar2,  dmodPapel, DMod00a, sysvar13, Ultra00a, Sysutil, Bdatos2,
  bdatos13, bdatos, DModtemp, sysutil2;  //ces 18/02/2004

var
  chara11, chara12, ayer: string;
  personabolsa: personacnvs;
  CliBolsa: integer;
  cliente9: clientes;
  lista, lista1: tstringlist;
{$R *.DFM}

procedure TfrmLiquidacion.AjustaCodigo(var _chara11, _chara12: string);
begin
  {$MESSAGE WARN 'File: FOOUNIT contained in PACKAGE:-> FOOLIB'}
  if (_chara11[13] = '&') then
    if (dmvar2.bolsa.tp_concepto <> 5) then
    begin
      _chara11 := copy(_chara11, 1, 12) + dmvar.final.co_final;
      _chara12 := dmvar.final.co_final;
    end
    else if trim(dmvar13.coAuxClienteCruce) = '' then
    begin
      _chara11 := copy(_chara11, 1, 12) + dmvar.final.co_final;
      _chara12 := dmvar.final.co_final;
    end
    else
    begin
      _chara11 := copy(_chara11, 1, 12) + dmvar13.coAuxClienteCruce;
      _chara12 := dmvar13.coAuxClienteCruce;
    end;
  if _chara11[13] = '#' then
    _chara11 := copy(_chara11, 1, 12) + dmvar.final.co_contable;
  if _chara11[13] = '-' then
    _chara11 := copy(_chara11, 1, 12);
end;

procedure TfrmLiquidacion.Genera_cmi_Cli;
var
  chara11, observa1, observa2, observa: string;
  ftasa : Double;
begin
  with DMvar2.asignacion do
  begin
    if tp_concepto = 1 then
      chara := ' V '
    else
      chara := ' C ';
    observa := loper(nu_oper_bolsa) + ' ' + dmvar.final.co_final + copy(display_d(ca_valor, 12, 1), 1, 10);
    observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
    observa2 := display_d(mt_valor, 8, 2) + ' ' + co_cta_custodia;

			//Debido a que no se tiene mas espacio disponible en la variable co_pagar_cmi,
			//se utilizan los 14 digitos, si son diferentes a blanco,
			//si en la posicion 13 existe # � - se asigna el valor por defecto.
			//Esto se hace para mantener la asignacion del auxiliar del cliente como estava
			//o colocarle el auxiliar de dos d�gitos que seleccione el cliente
    chara11 := arma_cuenta('CmixC', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_cmi_x_cob, 0);   //ces 23/01/2006
    if (chara11[13] <> '#') and (chara11[13] <> '-') and (chara11[13] <> '&') then
      if length(chara11) > 12 then

      else if (dmvar13.swAuxCliCon) and (not dmvar13.personacnv.sw_cmi_x_cob) then //ces 23/01/2006
        chara11 := chara11 + Busca_AuxCliente(dmvar13.swAuxCliCon, tp_concepto);

    chara11 := reemplazaAuxiliarContable(chara11);
    // if chara11[13] = '&' then
    //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
    // if chara11[13] = '#' then
    //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
    if chara11[13] = '-' then
      chara11 := copy(chara11, 1, 12);
      //esta condicion deberia estar incluida en el parametro  //if dmvar13.swCostosLiquida //ces  17/08/2009
 //     if dmvar2.calendario1.nu_corredor = 26 then //provincial
 //    quitamos la condicion para que se incluya el asiento para las operaciones fecha valor = T //ces & Nadia //06/06/2016 //Caso 1026 //ces 01/06/2016

    if (pos('MERCOSUR', uppercase(dmvar.calendario.tx_dominio)) > 0) or
       (pos('INVERCAPITAL', uppercase(dmvar.calendario.tx_dominio)) > 0) then     // Jhoannys  Caso 7127 26/02/2020
    begin
      if not dmpapel.tbdfactura.Active then
        dmpapel.tbdfactura.open;
      carga_indices(dmpapel.tbdfactura, dmvar.iddfa);
      DMpapel.tbdfactura.indexname := dmvar.IDdfa[2];
      dmpapel.tbdfactura.setrange([nu_asignacion], [nu_asignacion]);
      dmpapel.tbdfactura.first;
      while not DMpapel.tbdfactura.eof do
      begin
        carga_dfactura(DMpapel.tbdfactura);

        dmpapel.tbdfactura.next;
      end;

      ftasa := 1;
      if dmvar.titulo.nu_moneda <> 0 then
      begin
        DM00a.busca_precio(ceros(lintstr(dmvar.titulo.nu_moneda,6)),flch_a_jul(TXTdesde.text));
        ftasa := dmvar.precio.mt_precio;
      end;
      if mt_comision + mt_ajuste > 0 then   // Jfiguera a�adido if
        graba_linea(arma_cuenta('CmiCli', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, ceros(lintstr(DMvar2.dfactura.nu_factura, 8)), mt_comision + mt_ajuste, ftasa, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);
      if mt_isv_comision > 0 then      // Jfiguera a�adido if
        graba_linea(arma_cuenta('IvaCli', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, ceros(lintstr(DMvar2.dfactura.nu_factura, 8)), redondea(mt_isv_comision * ftasa, 2), 1, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '91', ' ', loper(nu_oper_bolsa), 0);
    end
    else                                                                       // Fin Jhoannys  Caso 7127 26/02/2020
    begin
      ftasa := 1;
      if DMvar2.asignacion.nu_oper_bolsa = DMvar2.bolsa.nu_oper_bolsa then
        ftasa := DMvar2.bolsa.mt_tasa_cambio;



      if mt_comision + mt_ajuste > 0 then   // Jfiguera a�adido if
        graba_linea(arma_cuenta('CmiCli', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)ojo}, observa, ceros(lintstr(nu_asignacion, 8)), mt_comision + mt_ajuste, ftasa, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);

      if mt_isv_comision > 0 then      // Jfiguera a�adido if
        graba_linea(arma_cuenta('IvaCli', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision, 2), ftasa, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '91', ' ', loper(nu_oper_bolsa), 0);
    end;

    if mt_iva_esp > 0 then
    begin
      if mt_comision + mt_ajuste > 0 then   // Jfiguera a�adido if
        graba_linea(arma_cuenta('IvaAct', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), 1, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '92', ' ', loper(nu_oper_bolsa), 0);
      if mt_isv_comision > 0 then      // Jfiguera a�adido if
        graba_linea(arma_cuenta('IvaOtr', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), 1, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '92', ' ', loper(nu_oper_bolsa), 0);
    end;
  end;
end;

 //ces 18/02/2004
function tfrmliquidacion.suma_dlia(desde: string; veces: integer; conferiado: boolean): string;
label
  repite;
var
  dd, aa: integer;
  l, ll: integer;
begin
  suma_dlia := desde;
  for ll := 1 to abs(veces) do
  begin
    val(copy(desde, 5, 3), dd, l);
    val(copy(desde, 1, 4), aa, l);
repite:
    if veces > 0 then
      dd := dd + 1
    else
      dd := dd - 1;
    l := aa mod 4;
    if (dd > 365) and (l > 0) or (dd > 366) and (l = 0) then
    begin
      aa := aa + 1;
      dd := 1;
    end;
    if dd <= 0 then
    begin
      aa := aa - 1;
      l := aa mod 4;
      dd := 365;
      if l = 0 then
        dd := 366;
    end;
    if conferiado then
      if (dlia_semana(jul_a_flch(ceros(lintstr(aa, 4) + lintstr(dd, 3)))) > 5) then
        goto repite;
    desde := ceros(lintstr(aa, 4) + lintstr(dd, 3));
    suma_dlia := desde;
  end;
end;

procedure TFRMliquidacion.Graba_linea(cta, observa, ref: string; mto, tasa: double; debcre: boolean; observa1, observa2, origen, clave, ref2, ref3: string; num_corre: integer);
begin
  if cta[1] = '-' then
    exit;
  with DMvar13.dxompro do
  begin
    nu_comprobante := DMvar.compro.nu_comprobante;
    sw_del := false;
    fl_comprobante := DMvar.compro.fl_comprobante;
    filler := observa1;
    co_cuenta := cta;
    co_cuentax := observa2;
    sw_deb_cre := debcre;
    mt_dcompro := redondea(mto, 2);
    nu_correspo := num_corre;
    tx_observa := observa;
    nu_ref := ref;
    nu_ref1 := copy(ref, 7, 6);
    mt_tasa := tasa;
    nu_mesa := 1;
    filler2 := txt(ref2, 10) + txt(ref3, 13);
    co_clave := clave;
    co_paso := origen;
    nu_secuencia := 0;
    DMpapel.TBdcompro.insert;
    Graba_dxompro(DMpapel.TBdcompro);
    DMpapel.TBdcompro.post;
  end;
  if debcre then
  begin
    DMvar.compro.mt_debito := DMvar.compro.mt_debito + DMvar13.dxompro.mt_dcompro;
    DMvar.compro.nu_debito := DMvar.compro.nu_debito + 1;
  end
  else
  begin
    DMvar.compro.mt_credito := DMvar.compro.mt_credito + DMvar13.dxompro.mt_dcompro;
    DMvar.compro.nu_credito := DMvar.compro.nu_credito + 1;
  end;
  DMpapel.TBcompro.edit;
  Graba_compro(DMpapel.TBcompro);
  DMpapel.TBcompro.post;

  if swLog then
  begin
    if logAsientosLiquida = nil then
      logAsientosLiquida := TLogAsiento.Create('C:\logAsientos\Liquidacion.txt');

    logAsientosLiquida.grabaAsiento(dmvar13.dxompro);
  end;


end;

procedure Tfrmliquidacion.genera_reverso_derecho_bol(origen: string; nuconcepto: integer);
var
  auxpersona: personacnvs;
  observa, observa1, observa2: string;
  cant1: double;
begin
  with DMvar2.bolsa do
  begin
   //se utiliza la contrapartida (asignacion) para saber cual fue el cliente original
    cant1 := 1;
    if dmvar.titulo.sw_f_v_u_o = 'P' then
      cant1 := 100;
    EfectivoBolsa := dmvar2.bolsa.mt_valor * dmvar2.asignacion.ca_valor / cant1 * dmvar2.bolsa.mt_tasa_cambio;
    if (nuconcepto = 0) and ((dmvar.final.tp_cliente = 'P')) then // Jfiguera a�adido la M y la Z
      EfectivoBolsa := EfectivoBolsa + dmvar2.bolsa.mt_comision1;
    chara := ' C ';
    if nuconcepto = 1 then
      chara := ' V ';
    if origen = '' then
      origen := 'B' + nu_oper_bolsa;
    observa := 'Rv' + nu_oper_bolsa + ' BVC000' + copy(display_d(dmvar2.asignacion.ca_valor, 12, 1), 1, 10);
    observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
    observa2 := txt(display_d(mt_valor, 8, 2), 15){+co_cta_custodia};
			//cuando el cliente compra la casa de bolsa vende, por eso se invierte el concepto
			//Busco el cliente bolsa  para armar la cuenta de reverso con la bvc
    dmpapel.tbfinal.indexname := dmvar.idfin[0];
    dmpapel.tbfinal.findkey(['BVC000']);
    carga_final(dmpapel.tbfinal);
    dmpapel.tbadiciona.indexname := dmvar.idadi[0];
    DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
    Carga_adiciona(DMpapel.TBadiciona);
    DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
    carga_personacnv(DMpapel.TBtpersonacnv);
    dmpapel.tbfinal.indexname := dmvar.idfin[2];
    graba_linea(arma_cuenta('Res', nuconcepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(dmvar13.swAuxCliCon, 0), observa, ceros(lintstr(nu_bolsa, 8)), EfectivoBolsa, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, origen, lintstr(nuconcepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(nuconcepto + 3, 2)), ' ', loper(nu_oper_bolsa), 0);

    graba_linea(arma_cuenta('Der', nuconcepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(dmvar13.swAuxCliCon, 0), observa, ceros(lintstr(nu_bolsa, 8)), EfectivoBolsa, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, origen, lintstr(nuconcepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(nuconcepto + 3, 2)), ' ', loper(nu_oper_bolsa), 0);

  end;
end;

procedure Tfrmliquidacion.genera_reverso_derecho_cli(origen: string);
var
  observa, observa1, observa2: string;
begin
  with DMvar2.asignacion do
  begin
    if tp_concepto = 1 then
      chara := ' V '
    else
      chara := ' C ';
    if origen = '' then
      origen := 'A' + nu_oper_bolsa;

    observa := 'Rv' + nu_oper_bolsa + ' ' + dmvar.final.co_final + copy(display_d(ca_valor, 12, 1), 1, 10);
    observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
    observa2 := txt(display_d(mt_valor, 8, 2) + ' ' + co_cta_custodia, 15);
   //cuando el cliente compra la casa de bolsa vende, por eso se invierte el concepto
    graba_linea(arma_cuenta('Res', tp_concepto = 0, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_AuxCliente(dmvar13.swAuxCliCon, 0), observa, ceros(lintstr(nu_asignacion, 8)), EfectivoCli, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, origen, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 7, 2)), ' ', loper(nu_oper_bolsa), 0);

    graba_linea(arma_cuenta('Der', tp_concepto = 0, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_AuxCliente(dmvar13.swAuxCliCon, 0), observa, ceros(lintstr(nu_asignacion, 8)), EfectivoCli, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, origen, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 7, 2)), ' ', loper(nu_oper_bolsa), 0);

  end;
end;

procedure Tfrmliquidacion.Button1Click(Sender: TObject);

  procedure Graba_cabeza;

    function Busca_sig(fec: string): longint;
    var
      compro1: comprobantes;
    begin
      with DMpapel.TBcompro do
      begin
        busca_sig := 0;
        compro1 := DMvar.compro;
        indexname := DMvar.IDcmp[0];
        setrange([DMvar.numero_mesa, fec], [DMvar.numero_mesa, fec]);
        first;
        if eof then
          compro1.nu_comprobante := 0
        else
          while (not eof) do
          begin
            carga_compro(DMpapel.TBcompro);
            compro1.nu_comprobante := DMvar.compro.nu_comprobante;
            next;
          end;
        DMvar.compro := compro1;
        cancelrange;
      end;
      busca_sig := DMvar.compro.nu_comprobante + 1;
    end;

  begin
    with DMvar.compro do
    begin
      fl_comprobante := flch_a_jul(TXTdesde.text);
      nu_comprobante := busca_sig(fl_comprobante);
      nu_vehiculo := 98;
      nu_ts := 0;
      nu_mesa := 1;
      nu_contab := 0;
      sw_estado := 0;
      nu_moneda := 0;
      mt_debito := 0;
      mt_credito := 0;
      nu_debito := 0;
      nu_credito := 0;
      tx_concepto1 := 'Liquidacion ' + TXTdesde.text;
      tx_concepto2 := 'Generado ' + DMvar.fecha_hoy + ' ' + timetostr(time);
      tx_concepto3 := '';
      tx_concepto4 := '';
      tx_concepto5 := '';
      tx_concepto6 := '';
      co_paso := '';
      filler := ' ';
    end;
    DMpapel.TBcompro.insert;
    Graba_compro(DMpapel.TBcompro);
    DMpapel.TBcompro.post;
    Carga_compro(DMpapel.TBcompro);
  end;

  function RevisaPaso(num_paso: string): boolean;
  var
    i: integer;
  begin
    result := false;
    for i := 0 to lista.Count - 1 do
      if lista.strings[i] = num_paso then
      begin
        result := true;
        break;
      end;
  end;

  procedure Liquida_Cartera;

    procedure BuscaPosi(_ayer: string);   //ces 18/02/2004
    var
      i, j, nuoper: integer;
      asigna9: asignaciones;
      bolsa9: bolsas;
      existe: boolean;
      cant1: double;
    begin
      PosicionHoy := 0;
      CapitalHoy := 0;
      PrecioProm := 0;
      asigna9 := dmvar2.asignacion;
      bolsa9 := dmvar2.bolsa;
      dmpapel.tbactivoscont.cancelrange;
      _ayer := suma_dlia(_ayer, -1, false);  //ces 18/02/2004
      cant1 := 1;
      if dmvar.titulo.sw_f_v_u_o = 'P' then
        cant1 := 100;

      with asigna9 do
        if dmpapel.tbactivoscont.findkey([_ayer, nu_cliente,  //ces 18/02/2004
          co_cta_custodia, co_valor]) then
        begin
          carga_inventariosc(dmpapel.tbactivoscont);
          posicionhoy := trunc(dmvar2.inventarioc.ca_valor);
          if posicionhoy <> 0 then
          begin
            if (dmvar.titulo.mt_interes < 0.01) and (dmvar.titulo.sw_f_v_u_o = 'P') then //precio tac 23/01/2004
            begin                                                                       //precio tac 23/01/2004
              capitalhoy := abs(posicionhoy * dmvar2.inventarioc.mt_preciotac / cant1);     //precio tac 23/01/2004
              precioprom := dmvar2.inventarioc.mt_preciotac;                            //precio tac 23/01/2004
            end                                                                         //precio tac 23/01/2004
            else                                                                         //precio tac 23/01/2004
            begin                                                                       //precio tac 23/01/2004
              capitalhoy := abs(posicionhoy * dmvar2.inventarioc.mt_valor / cant1);
              precioprom := dmvar2.inventarioc.mt_valor;
            end;                                                                        //precio tac 23/01/2004
          end;
        end
        else
        begin
          dmvar2.inventarioc.ca_valor := 0;
          dmvar2.inventarioc.mt_valor := 0;
        end;
      dmaux.tbasigna.indexname := dmvar.idasi[6];
      i := 0;
      existe := false;
      while (i <= lista.count - 1) and (not existe) do
        with dmvar2.asignacion do
        begin
          val(copy(lista.strings[i], pos(';', lista.strings[i]) + 1, 6), nuoper, j);
          dmaux.tbasigna.findkey([nuoper]);
          carga_asigna(DMaux.TBasigna);
//     existe := busca_titulo(co_valor);
          cant1 := 1;
          if dmvar.titulo.sw_f_v_u_o = 'P' then
            cant1 := 100;
          dmaux.tbbolsa.findkey([nu_oper_bolsa, tp_operacion]);
          carga_bolsa(dmaux.tbbolsa);
          existe := nu_cliente > asigna9.nu_cliente;
          if nu_oper_bolsa < asigna9.nu_oper_bolsa then
            if asigna9.co_valor = co_valor then
              if asigna9.nu_cliente = nu_cliente then
                if asigna9.co_cta_custodia = co_cta_custodia then
                  if trunc(posicionhoy) >= 0 then
                    if tp_concepto = 0 then //largo comprando
                    begin
                      posicionhoy := trunc(posicionhoy + ca_valor);
                      if dmvar2.calendario1.nu_corredor <> 32 then
                        capitalhoy := capitalhoy + ca_valor * mt_valor / cant1 + (dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor) + mt_comision_ext
                      else
                       capitalhoy := capitalhoy + ca_valor * mt_valor / cant1 ; // Jfiguera algunas cosas pueden salir mal con esto para mercosur, asumo la responsabilidad.

                       
                      precioprom := capitalhoy / posicionhoy * cant1;
                    end
                    else
                    begin
											//largo vendiendo
                      if trunc(abs(posicionhoy)) = 0 then
                        capitalhoy := ca_valor * mt_valor / cant1;
                      posicionhoy := trunc(posicionhoy - ca_valor);
												//lango vendiendo y paso a corto
                      if trunc(posicionhoy) < 0 then
                      begin
                        capitalhoy := abs(posicionhoy * mt_valor / cant1);
                        precioprom := mt_valor;
                      end;
                      if trunc(posicionhoy) > 0 then  //largo y sigo largo  //aqui yoli 27/09
                        capitalhoy := capitalhoy - (ca_valor * precioprom / cant1); //aqui yoli 27/09
                    end
                  else if tp_concepto = 1 then //corto vendiendo
                  begin
                    posicionhoy := trunc(posicionhoy - ca_valor);
                    capitalhoy := capitalhoy + ca_valor * mt_valor / cant1;
                    precioprom := abs(capitalhoy / posicionhoy * cant1);
                  end
                  else
                  begin
												//corto comprando
                    if trunc(abs(posicionhoy)) = 0 then
                      capitalhoy := ca_valor * mt_valor / cant1 + (dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor) + mt_comision_ext;
                    posicionhoy := trunc(posicionhoy + ca_valor);
												//corto comprando y paso a largo
                    if trunc(posicionhoy) > 0 then
                      capitalhoy := abs(posicionhoy * mt_valor / cant1 + (dmvar2.bolsa.mt_comision1 * posicionhoy / dmvar2.bolsa.ca_valor) + (mt_comision_ext * posicionhoy / ca_valor))
                    else if trunc(posicionhoy) < 0 then
                      capitalhoy := abs(posicionhoy * precioprom) / cant1;
                  end;
          inc(i)
        end;
      dmvar2.asignacion := asigna9;
      dmvar2.bolsa := bolsa9;
    end;

  var
    monto, monto1, cant1, monto_derecho, montox: double;
    chara, observa, observa1, observa2, txtmonto, _origen, _aux: string;
  begin
    with dmvar2.asignacion do
    begin
      escribelog(rutalog, 'liquida_cartera');
      dmpapel.tbbolsa.CancelRange;
      dmpapel.tbbolsa.indexname := dmvar.IDbol[0];
      dmpapel.tbbolsa.findkey([nu_oper_bolsa, 0]);
      carga_bolsa(dmpapel.tbbolsa);
      if tp_concepto = 1 then
        chara := ' V '
      else
        chara := ' C ';
      observa := loper(nu_oper_bolsa) + ' ' + dmvar.final.co_final + copy(display_d(ca_valor, 12, 1), 1, 10);
      observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
      observa2 := txt(display_d(mt_valor, 8, 2) + ' ' + co_cta_custodia, 15);
		//busco precio promedio de ayer
      buscaposi(flch_a_jul(txtdesde.text));
      monto_derecho := dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor;
      if (DMvar2.calendario1.sw_gastoscart) {or ((dmvar2.calendario1.nu_corredor <> 6) and (dmvar2.calendario1.nu_corredor <> 10) and (dmvar2.calendario1.nu_corredor <> 49) and (dmvar2.calendario1.nu_corredor <> 68)
          and (DMvar2.calendario1.nu_corredor <> 48) and (DMvar2.calendario1.nu_corredor <> 66) and (DMvar2.calendario1.nu_corredor <> 64)
          and (DMvar2.calendario1.nu_corredor <> 71) and (DMvar2.calendario1.nu_corredor <> 1) and (DMvar2.calendario1.nu_corredor <> 77))} then
        monto_derecho := 0;

      cant1 := 1;
      if dmvar.titulo.sw_f_v_u_o = 'P' then
        cant1 := 100;
      //chara11 := arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C') + trim(busca_auxcliente(true, 0)) + trim(busca_auxtitulo);  11048
      chara11 := arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C');
      
      chara11 := reemplazaAuxiliarContable(chara11);
      // if chara11[13] = '&' then
      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
      // if chara11[13] = '#' then
      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
      if chara11[13] = '%' then
        chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
      if chara11[13] = '-' then
        chara11 := copy(chara11, 1, 12);
      if chara11[13] = '@' then
        chara11 := copy(chara11, 1, 12) + '001';
      if chara11[13] = '%' then
        chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
      if tp_concepto = 0 then
      begin
        if trunc(posicionhoy) >= 0 then //largo comprando
      //Inversiones en Titulos valores
        begin
          if (dmvar2.calendario1.nu_corredor = 61) or (dmvar2.calendario1.nu_corredor = 10) or (dmvar2.calendario1.nu_corredor = 49) or (dmvar2.calendario1.nu_corredor = 68) or (dmvar2.calendario1.nu_corredor = 48) or (DMvar2.calendario1.nu_corredor = 66) or (DMvar2.calendario1.nu_corredor = 1) or (dmvar2.calendario1.nu_corredor = 77) and (dmvar2.calendario1.nu_corredor = 64) then
            monto := ca_valor * mt_valor / cant1 + dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor + mt_comision_ext
          else
            monto := (ca_valor * mt_valor / cant1 + dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor);

          if (dmvar2.calendario1.nu_corredor = 72) then        // Jfiguera 7711
            monto := dmvar2.asignacion.mt_neto;                                                         // Jfiguera 03-09-2020 a�adido ahora el corredor 71


          monto1 := 0;
          _origen := '40';
          if dmvar.titulo.sw_f_v_u_o = 'P' then
          begin
            _origen := '41';
            graba_linea(arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Inv ' + dmvar.final.co_final, 12), monto, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0)
          end
          else
          begin
            graba_linea(chara11, observa, txt('Inv ' + dmvar.final.co_final, 12), monto - monto_derecho, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0);

            montox := monto_derecho;
            if DMvar2.bolsa.tp_concepto = 5 then
              monto_derecho := monto_derecho / 2;

            if monto_derecho > 0 then      // Jfiguera   7461 si el monto de derecho esta en cero que no se guarde
            begin
              graba_linea(arma_cuenta('CmixP', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('CmiBVC. ' + dmvar.final.co_final, 12), monto_derecho, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
            end;


         //Vanessa 31/01/2020 caso 6985 lo quito porque esta descuadrando el comprobante de cruces cuando el puesto compra
            {if (pos('SOLFIN', UpperCase(DMvar.calendario.tx_dominio)) = 0) and (pos('VALORALTA', UpperCase(DMvar.calendario.tx_dominio)) = 0) and (pos('STATERA', UpperCase(DMvar.calendario.tx_dominio)) = 0) and
            (dmvar2.calendario1.nu_corredor <> 72) and (dmvar2.calendario1.nu_corredor <> 71) then   //Jfiguera 7711
            begin
              if dmvar2.bolsa.tp_concepto = 5 then// solo para los cruces para no repetir el asiento mas abajo. CES 06/09/2019 caso 6299
                if dmvar.final.tp_cliente = 'P' then   // Jfiguera si es cartera propia hago lo contrario.
                begin

                  observa := 'OTRAS PARTIDAS X APLICAR';
                  if dmvar2.asignacion.tp_operacion = 1 then
                    graba_linea(arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Inv ' + dmvar.final.co_final, 12), (monto - montox) + monto_derecho,DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0)
                  else
                    graba_linea(arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Inv ' + dmvar.final.co_final, 12), (monto - montox) + monto_derecho,DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0)
                end;
            end;}

          end;
        end
        else //corto compro
        begin
        //Inversiones en Titulos valores. Entra en cartera a precio prom. de venta
          _origen := '40';

          if posicionhoy + ca_valor <= 0 then
            monto1 := ca_valor * abs(capitalhoy / posicionhoy)
          else
            monto1 := capitalhoy + abs(ca_valor - trunc(abs(posicionhoy))) * mt_valor / cant1;

        // ganancia o perdida realizada
          if posicionhoy + ca_valor <= 0 then
            monto := ca_valor * (abs(capitalhoy / posicionhoy) - mt_valor / 100) - monto_derecho
          else
            monto := ((abs(capitalhoy / posicionhoy) * cant1) - dmvar2.asignacion.mt_valor) * abs(posicionhoy) / cant1 - monto_derecho;
          if monto > 0 then
            if dmvar.titulo.sw_f_v_u_o = 'P' then
              _origen := '40' //ganancia renta fija
            else
              _origen := '41'                                 //ganancia renta variable
          else if dmvar.titulo.sw_f_v_u_o = 'P' then
            _origen := '42'  //perdida renta fija
          else
            _origen := '43';                                  //perdida renta variable

          if dmvar.titulo.sw_f_v_u_o = 'P' then
          begin
            graba_linea(arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Inv ' + dmvar.final.co_final, 12), abs(monto1), {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0);
          end
          else
            graba_linea(chara11, observa, txt('Inv ' + dmvar.final.co_final, 12), abs(monto1), {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0);

				// ganancia o perdida realizada
          if posicionhoy + ca_valor <= 0 then
            monto := ca_valor * (abs(capitalhoy / posicionhoy) - mt_valor / 100) - monto_derecho
          else
            monto := ((abs(capitalhoy / posicionhoy) * cant1) - dmvar2.asignacion.mt_valor) * abs(posicionhoy) / cant1 - monto_derecho;
          if monto > 0 then
            chara := 'GanR'
          else
            chara := 'PerR';
          chara11 := arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C') {+ trim(busca_auxcliente(true, 0))} + trim(busca_auxtitulo);
          if chara = 'GanR' then
            if dmvar13.tptcontcnv.sw_ganancia then
              chara11 := arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C')
            else


          else if dmvar13.tptcontcnv.sw_perdida then
            chara11 := arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C');

          chara11 := reemplazaAuxiliarContable(chara11);           
          // if chara11[13] = '&' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          // if chara11[13] = '#' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '@' then
            chara11 := copy(chara11, 1, 12) + '001';
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);

          if dmvar.titulo.sw_f_v_u_o = 'P' then
            graba_linea(arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt(chara + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, monto > 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0)
          else
            graba_linea(chara11, observa, txt(chara + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, monto > 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + _origen, ' ', loper(nu_oper_bolsa), 0);
          monto := monto1 - monto;

          if monto_derecho > 0 then
          begin
            if DMvar2.bolsa.tp_concepto = 5 then
              monto_derecho := monto_derecho / 2;

            graba_linea(arma_cuenta('CmiBVC', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('CmiBVC. ' + dmvar.final.co_final, 12), monto_derecho, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', loper(nu_oper_bolsa), 0);
            monto := monto + monto_derecho;
          end;
        end; //corto comprando

        if mt_comision_ext > 0.01 then
        begin
          chara11 := arma_cuenta('CVVxP', true, true, dmvar.titulo.nu_moneda, 1, 'C');
          if (dmvar2.calendario1.nu_corredor <> 61) then
            graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0)
          else
            monto := monto - mt_comision_ext;
          chara11 := arma_cuenta('CmiCVV', true, true, dmvar.titulo.nu_moneda, 1, 'C');
          if chara11[13] = '@' then
            chara11 := copy(chara11, 1, 12) + '001';
          if chara11[13] = '?' then
            chara11 := copy(chara11, 1, 12) + 'CVV001';
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
        end;
      end
      else
      begin //venta


        //chara11 := arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C') + trim(busca_auxcliente(true, 0));  11048
        chara11 := arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C');
        chara11 := reemplazaAuxiliarContable(chara11);
        // if chara11[13] = '&' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        if posicionhoy <= 0 then //corto vendiendo
        begin
        //Inversiones en Titulos valores
          monto := ca_valor * mt_valor / cant1;
          monto1 := 0;
          if dmvar.titulo.sw_f_v_u_o = 'P' then
            graba_linea(chara11, observa, txt('Inv ' + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0)
          else
            graba_linea(chara11, observa, txt('Inv ' + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
        end
        else //largo y vendo
        begin
				//Inversiones en Titulos valores. Sale de cartera a precio prom. de compra
          if posicionhoy - ca_valor >= 0 then
            monto1 := ca_valor * precioprom / cant1
          else
            monto1 := posicionhoy * precioprom / cant1 + abs(ca_valor - trunc(abs(posicionhoy))) * mt_valor / cant1 + mt_comision_ext;

          if dmvar.titulo.sw_f_v_u_o = 'P' then
            graba_linea(arma_cuenta('Inv', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Inv ' + dmvar.final.co_final, 12), abs(monto1), {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0)
          else
            graba_linea(chara11, observa, txt('Inv ' + dmvar.final.co_final, 12), abs(monto1), {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);

				// ganancia o perdida realizada. Monto < 0 gano plata
          if posicionhoy - ca_valor >= 0 then
            monto := ca_valor * (mt_valor - precioprom) / cant1
          else
            monto := (dmvar2.asignacion.mt_valor - precioprom) * posicionhoy / cant1;

          if monto > 0 then
            chara := 'GanR'
          else
            chara := 'PerR';
          chara11 := arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C') {+ trim(busca_auxcliente(true, 0)) }+ trim(busca_auxtitulo);
          if chara = 'GanR' then
            if dmvar13.tptcontcnv.sw_ganancia then
              chara11 := arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C')
            else


          else if dmvar13.tptcontcnv.sw_perdida then
            chara11 := arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C');
          chara11 := reemplazaAuxiliarContable(chara11);  
          // if chara11[13] = '&' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          // if chara11[13] = '#' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          if abs(monto) > 0.01 then
            if dmvar.titulo.sw_f_v_u_o = 'P' then
              graba_linea(arma_cuenta(chara, true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt(chara + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, monto > 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '61', ' ', loper(nu_oper_bolsa), 0)
            else
              graba_linea(chara11, observa, txt(chara + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, monto > 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '62', ' ', loper(nu_oper_bolsa), 0);
          monto := monto + monto1;
        end;

        if mt_islr > 0.01 then
        begin
          chara11 := arma_cuenta('ISLR', true, true, dmvar.titulo.nu_moneda, 1, 'C');
          if chara11[13] = '@' then
            chara11 := copy(chara11, 1, 12) + '001';
          if chara11[13] = '?' then
            chara11 := copy(chara11, 1, 12) + 'ISLR01';
          graba_linea(chara11, observa, txt('ISLR. ' + dmvar.final.co_final, 12), ca_valor * mt_valor * mt_islr / 100, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
          monto := monto - ca_valor * mt_valor * mt_islr / 100;
        end;

        if mt_comision_ext > 0.01 then
        begin
          chara11 := arma_cuenta('CVVxP', true, true, dmvar.titulo.nu_moneda, 1, 'C');
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
          chara11 := arma_cuenta('CmiCVV', true, true, dmvar.titulo.nu_moneda, 1, 'C');
          if chara11[13] = '@' then
            chara11 := copy(chara11, 1, 12) + '001';
          if chara11[13] = '?' then
            chara11 := copy(chara11, 1, 12) + 'CVV001';
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
        end;
      end;

      if dmvar.titulo.sw_f_v_u_o = 'P' then
        if dmvar.titulo.mt_interes > 0.01 then
          if tp_concepto = 0 then
          begin
            monto := monto + mt_interes;
            graba_linea(arma_cuenta('Int', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Int' + dmvar.final.co_final, 12), mt_interes, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 1, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
          end
          else
          begin
            monto := monto + mt_interes;
            graba_linea(arma_cuenta('Int', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('Int' + dmvar.final.co_final, 12), mt_interes, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 1, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
          end;


      if (tp_concepto = 1)  then
      begin
          //21/11/02 //asi estaba en esta fecha. cambiado el 21/11/03
                    // NO reversaba la comision por pagar en fecha de liquidacion
//21/11/03					graba_linea(arma_cuenta('CmiBVC',true,true,dmvar.titulo.nu_moneda,1,'C'),observa,
        if DMvar2.bolsa.tp_concepto = 5 then
          graba_linea(arma_cuenta('CmixP', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('CmiBVC. ' + dmvar.final.co_final, 12), (dmvar2.bolsa.mt_comision1 / 2) * ca_valor / dmvar2.bolsa.ca_valor, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0)
        else
          graba_linea(arma_cuenta('CmixP', true, true, dmvar.titulo.nu_moneda, 1, 'C'), observa, txt('CmiBVC. ' + dmvar.final.co_final, 12), dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);

          // Jfiguera 7461 que sume el derecho de registro si es mercosur, no sabemos por que siempre restaba
//         if (pos('MERCOSUR',uppercase(dmvar.calendario.tx_dominio)) = 0) then
//          begin
//            monto := monto-dmvar2.bolsa.mt_comision1*ca_valor/dmvar2.bolsa.ca_valor;
////          end else monto := monto+dmvar2.bolsa.mt_comision1*ca_valor/dmvar2.bolsa.ca_valor;
//          end else monto := monto-(dmvar2.bolsa.mt_comision1/2)*ca_valor/dmvar2.bolsa.ca_valor;

        if DMvar2.bolsa.tp_concepto = 5 then
          monto := monto - (dmvar2.bolsa.mt_comision1 / 2) * ca_valor / dmvar2.bolsa.ca_valor
        else
          monto := monto - dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor;

      end;

     (* if (DMvar2.bolsa.tp_concepto <> 5) then
      begin

        if (tp_concepto = 0) {or (dmvar2.bolsa.tp_concepto = 5)} then //compras o cualquier operacion de cruce
        begin
          chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, 0);   //ces 13/10/2004
          if chara11[13] = '&' then
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          if chara11[13] = '#' then
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '@' then
            chara11 := copy(chara11, 1, 12) + '001';
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          if (dmvar2.calendario1.nu_corredor = 61) {or (dmvar2.calendario1.nu_corredor = 10)} then
          begin
            chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000'; // BNH. LA GORDA y caja
            if dmvar2.bolsa.tp_concepto = 5 then
              monto := dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor;
          end;
          graba_linea(chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
          str(monto: 18: 2, txtmonto);
        end
        else
        begin
          chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidasV, 1);   //ces 13/10/2004
          if chara11[13] = '&' then
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          if chara11[13] = '#' then
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          if (dmvar2.calendario1.nu_corredor = 61) {or (dmvar2.calendario1.nu_corredor = 10)} then
            chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000'; // BNH. LA GORDA
          graba_linea(chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), abs(monto), {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
          str(monto: 18: 2, txtmonto);
        end;


      end;        *)


      // Jfiguera ESTE ELSE ESTABA MALISIMO, LAS CUENTAS DE OTRAS PARTIDAS SIEMPRE SE TIENEN QUE GENERAR.
     {  else if(tp_concepto = 1) then  //ces 06/09/2019       // Jfiguera 12972 03-05-2023 a�adido concepto 5
      begin
        if (dmvar2.calendario1.nu_corredor <> 83) and
           (dmvar2.calendario1.nu_corredor <> 72) and     //Jfiguera  7710 a�adido el corredor
           (dmvar2.calendario1.nu_corredor <> 52) AND      // Estas son las exceciones del derecho de registro
           (dmvar2.calendario1.nu_corredor <> 40) then    // Jfiguera 11505 a�adido corredor, deberia crecer en parametro
        begin
          chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C');    //ces 13/10/2004
          if chara11[13] = '&' then
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          if chara11[13] = '#' then
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          if (dmvar2.calendario1.nu_corredor = 61) then
            chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000'; // BNH. LA GORDA

          graba_linea(chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), abs(monto), DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
          str(monto: 18: 2, txtmonto);
        end; }


     { if (dmvar2.calendario1.nu_corredor <> 83) and
           (dmvar2.calendario1.nu_corredor <> 72) and     //Jfiguera  7710 a�adido el corredor
           (dmvar2.calendario1.nu_corredor <> 52) AND      // Estas son las exceciones del derecho de registro
           (dmvar2.calendario1.nu_corredor <> 40) then    // Jfiguera 11505 a�adido corredor, deberia crecer en parametro   }

        begin

          if DMVAR2.ASIGNACION.tp_concepto = 0 then            // Jfiguera  7712 a�adi el if, siempre armaba con la cuenta de compra
          begin
            chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C'){ + dmvar.final.co_final};
          end
          else chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C'){ + dmvar.final.co_final};

          chara11 := reemplazaAuxiliarContable(chara11);
          // if chara11[13] = '&' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          // if chara11[13] = '#' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);

          if (dmvar2.calendario1.nu_corredor = 61) then
            chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000'; // BNH. LA GORDA

          graba_linea(chara11,observa,txt('Otras Part. '+dmvar.final.co_final,12),abs({monto}mt_neto),DMvar2.bolsa.mt_tasa_cambio,tp_concepto = 0,observa1,observa2,
                      'A'+nu_oper_bolsa,lintstr(tp_concepto,1)+lintstr(dmvar.titulo.nu_moneda,1)+'15',' ',loper(nu_oper_bolsa),0);
          str(monto: 18: 2, txtmonto);
       END;
    end;
  end;

  procedure GeneraMutuoPasivo(origen: string);
  var
    observa1, observa2, observa, chara11, chara12: string;
    monto, precioprom, CapitalHoy, PosicionHoy, cant1: double;

    procedure BuscaPosi(_ayer: string); //ces 18/02/2004
    var
      i, j, nuoper: integer;
      asigna9: asignaciones;
      bolsa9: bolsas;
      existe: boolean;
    begin
      PosicionHoy := 0;
      CapitalHoy := 0;
      precioprom := 0;
      asigna9 := dmvar2.asignacion;
      bolsa9 := dmvar2.bolsa;
      dmpapel.tbactivoscont.cancelrange;
      cant1 := 1;
      _ayer := suma_dlia(_ayer, -1, false); //ces 18/02/2004
      if dmvar.titulo.sw_f_v_u_o = 'P' then
        cant1 := 100;
      with asigna9 do
        if dmpapel.tbactivoscont.findkey([_ayer, nu_cliente,  //ces 18/02/2004
          co_cta_custodia, co_valor]) then
        begin
          carga_inventariosc(dmpapel.tbactivoscont);
          PosicionHoy := trunc(dmvar2.inventarioc.ca_valor);
          if PosicionHoy <> 0 then
          begin
            if (dmvar.titulo.mt_interes < 0.01) and (dmvar.titulo.sw_f_v_u_o = 'P') then //precio tac 23/01/2004
            begin                                                                       //precio tac 23/01/2004
              CapitalHoy := abs(PosicionHoy * dmvar2.inventarioc.mt_preciotac / 100);     //precio tac 23/01/2004
              precioprom := dmvar2.inventarioc.mt_preciotac;                            //precio tac 23/01/2004
            end                                                                         //precio tac 23/01/2004
            else                                                                         //precio tac 23/01/2004
            begin                                                                       //precio tac 23/01/2004
              CapitalHoy := abs(PosicionHoy * dmvar2.inventarioc.mt_valor / cant1);
              precioprom := dmvar2.inventarioc.mt_valor;
            end;                                                                        //precio tac 23/01/2004
          end;
        end
        else
        begin
          dmvar2.inventarioc.ca_valor := 0;
          dmvar2.inventarioc.mt_valor := 0;
          precioprom := dmvar2.asignacion.mt_neto / dmvar2.asignacion.ca_valor;
        end;
    end;

  begin
    dmpapel.tbbolsa.indexname := dmvar.IDbol[0];
    dmpapel.tbbolsa.findkey([dmvar2.asignacion.nu_oper_bolsa, 0]);
    carga_bolsa(dmpapel.tbbolsa);
    if dmvar2.asignacion.tp_concepto = 1 then
      chara := ' V '
    else
      chara := ' C ';
    observa := loper(dmvar2.asignacion.nu_oper_bolsa) + ' ' + dmvar.final.co_final + copy(display_d(dmvar2.asignacion.ca_valor, 12, 1), 1, 10);
    observa1 := chara + jul_a_flch(dmvar2.asignacion.fl_fuera) + ' ' + dmvar2.asignacion.co_valor;
    if dmvar2.asignacion.tp_concepto = 0 then
      monto := dmvar2.asignacion.mt_neto
    else
    begin
      buscaPosi(flch_a_jul(txtdesde.text));
      monto := dmvar2.asignacion.ca_valor * precioprom;
    end;
    observa2 := txt(display_d(monto / dmvar2.asignacion.ca_valor, 8, 2) + ' ' + dmvar2.asignacion.co_cta_custodia, 15);
    chara11 := arma_cuenta('IMutuo', true, true, dmvar.titulo.nu_moneda, 1, 'C');
    if trim(busca_auxtitulo) <> '' then
      chara11 := copy(chara11, 1, 12);
    graba_linea(chara11 + trim(busca_auxtitulo), observa, txt('Inv M. ' + dmvar.final.co_final, 12), monto, 1, dmvar2.asignacion.tp_concepto = 1, observa1, observa2, origen, lintstr(dmvar2.asignacion.tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(dmvar2.bolsa.nu_oper_bolsa), 0);
    chara11 := arma_cuenta('OMutuo', true, true, dmvar.titulo.nu_moneda, 1, 'C') + trim(busca_auxcliente(true, 0));
    chara11 := reemplazaAuxiliarContable(chara11);
    // if chara11[13] = '&' then
    //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
    // if chara11[13] = '#' then
    //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
    if chara11[13] = '-' then
      chara11 := copy(chara11, 1, 12);

    graba_linea(chara11 + chara11[1], observa, txt('Obl M.' + dmvar.final.co_final, 12), monto, 1, dmvar2.asignacion.tp_concepto = 0, observa1, observa2, origen, lintstr(dmvar2.asignacion.tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(dmvar2.bolsa.nu_oper_bolsa), 0);
  end;

  procedure Liquida_cliente(porbanco: boolean);
  var
    existe: boolean;
    _chara11, _chara12, observa, observa1, observa2, txtmonto, _observa: string;
    CmiBolsa, monto, monto1: double;
    pabo9: pabos;
    cant1: double;
    final9: clientes;
    adiciona9: adicionales;
    personacnv9: personacnvs;
    auxasigna, asignapropia: asignaciones;
    crucepropia: boolean;
  begin
    escribelog(rutalog, 'Inicio liquida_cliente');
    pabo9 := dmvar.pabo;
    with dmvar2.asignacion do
    begin
      observa := loper(nu_oper_bolsa) + ' ' + dmvar.final.co_final + copy(display_d(ca_valor, 12, 1), 1, 10);
      if tp_concepto = 1 then
        chara := ' V '
      else
        chara := ' C ';
      observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
      observa2 := txt(display_d(mt_valor, 8, 2) + ' ' + co_cta_custodia, 13) + ceros(lintstr(dmvar.pabo.tp_pago, 2));
    end;
    if not porbanco then
      exit;

//  if existe then
    with dmvar2.asignacion do
    begin

      dmpapel.tbbolsa.cancelrange;
      dmpapel.tbbolsa.indexname := dmvar.IDbol[0];
      dmpapel.tbbolsa.findkey([nu_oper_bolsa, 0]);
      carga_bolsa(dmpapel.tbbolsa);

      with dmvar2.asignacion do
      begin
        dmpapel.tbcorre.FindKey([dmvar.pabo.nu_correspo]);
        carga_correspo(dmpapel.tbcorre);

        graba_linea(dmvar.correspo.co_contable, observa, txt(dmvar.pabo.nu_deposito, 12), mt_neto, {1}DMvar2.bolsa.mt_tasa_cambio, dmvar.pabo.tp_paso = 'E', observa1, observa2, //cambio de referencia ces 04/10/2004
          'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), dmvar.pabo.nu_deposito, loper(nu_oper_bolsa), dmvar.pabo.nu_correspo);

      end;

      if tp_concepto = 1 then
        chara := ' V '
      else
        chara := ' C ';
      observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
      observa2 := txt(display_d(mt_valor, 8, 2) + ' ' + co_cta_custodia, 15);
			//Debido a que no se tiene mas espacio disponible en la variable co_pagar_cmi,
			//se utilizan los 14 digitos, si son diferentes a blanco,
			//si en la posicion 13 existe # � - se asigna el valor por defecto.
			//Esto se hace para mantener la asignacion del auxiliar del cliente como estava
			//o colocarle el auxiliar de dos d�gitos que seleccione el cliente
      chara11 := arma_cuenta('CmixC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_cmi_x_cob, 0);   //ces 23/01/2006
      if (chara11[13] <> '#') and (chara11[13] <> '-') and (chara11[13] <> '&') then
        if length(chara11) > 12 then

        else if (dmvar13.swAuxCliCon) and (not dmvar13.personacnv.sw_cmi_x_cob) then //ces 23/01/2006
          chara11 := chara11 + Busca_AuxCliente(dmvar13.swAuxCliCon, tp_concepto);
      chara11 := reemplazaAuxiliarContable(chara11);    
      // if chara11[13] = '&' then
      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
      // if chara11[13] = '#' then
      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
      if chara11[13] = '-' then
        chara11 := copy(chara11, 1, 12);
      if chara11[14] = '@' then
        chara11 := copy(chara11, 1, 13);
      if dmvar13.swseparariva then
      begin
        if fl_transac <> fl_fuera then  //solo para transacciones spot
        begin
          if not dmvar13.swCostosLiquida then  //Vanessa 24/10/2017 solo si debo reversar la comision por cobrar
            if mt_comision + mt_ajuste + mt_isv_comision > 0.01 then
              graba_linea(chara11, observa, txt('CmixC ' + dmvar.final.co_final, 12), mt_comision + mt_ajuste + mt_isv_comision, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);
        end;
        //Vanessa 24/10/2017 la comision CVV siempre debe registrarse
        chara11 := arma_cuenta('CVVxP', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_gastos_cmi1, 0);   //ces 13/10/2004
        if chara11[13] = '?' then
          chara11 := copy(chara11, 1, 12) + 'CVV001';
        chara11 := reemplazaAuxiliarContable(chara11);  
        // if chara11[13] = '&' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '@' then
          chara11 := copy(chara11, 1, 12) + '001';
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        if mt_comision_ext > 0.01 then
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
      end
      else if fl_transac <> fl_fuera then  //solo para transacciones spot //Caso 1026 //ces 01/06/2016
      begin
        if mt_comision + mt_ajuste + mt_isv_comision > 0.01 then
      // Solicitud Interbursa
          if not dmvar13.swCostosLiquida then
            graba_linea(chara11, observa, txt('CmixC ' + dmvar.final.co_final, 12), redondea(mt_comision + mt_ajuste + mt_isv_comision, 2), {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0)
          else
        //esta condicion deberia estar incluida en el parametro  //if dmvar13.swCostosLiquida //ces  17/08/2009
if ((dmvar2.calendario1.nu_corredor <> 26) and (dmvar2.calendario1.nu_corredor <> 49) and (dmvar2.calendario1.nu_corredor <> 72)) then //provincial           // Jfiguera 7710 a�adido el corredor 72
            graba_linea(chara11, observa, txt('CmixC ' + dmvar.final.co_final, 12), mt_comision + mt_ajuste, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);
        chara11 := arma_cuenta('CmiCVV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_gastos_cmi1, 0);   //ces 13/10/2004
        if chara11[13] = '?' then
          chara11 := copy(chara11, 1, 12) + 'CVV001';
        chara11 := reemplazaAuxiliarContable(chara11);  
        // if chara11[13] = '&' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '@' then
          chara11 := copy(chara11, 1, 12) + '001';
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        if mt_comision_ext > 0.01 then
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
        if mt_comision_bolsa > 0.01 then
          CmiBolsa := 0
        else
          CmiBolsa := ca_valor * dmvar2.bolsa.mt_comision1 / dmvar2.bolsa.ca_valor;
        chara11 := arma_cuenta('CmiBVC', true, true, dmvar.titulo.nu_moneda, 1, 'C');
        if chara11[13] = '' then
          chara11 := arma_cuenta('CmiBVC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(dmvar13.swAuxCliLiq, 0);
        chara11 := reemplazaAuxiliarContable(chara11);  
        // if chara11[13] = '&' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        if mt_comision_bolsa < 0.01 then
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), CmiBolsa, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
        if mt_iva_esp > 0 then //reverso iva especial
        begin
          chara11 := arma_cuenta('IvaOtr', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C');
          chara11 := reemplazaAuxiliarContable(chara11);
          // if chara11[13] = '&' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
          // if chara11[13] = '#' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          graba_linea(chara11, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);
        end;
      end; //fl_transac <> fl_fuera

      if fl_transac = fl_fuera then
      begin
        chara11 := arma_cuenta('CmiCVV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_gastos_cmi1, 0);   //ces 13/10/2004
        if chara11[13] = '?' then
          chara11 := copy(chara11, 1, 12) + 'CVV001';

        chara11 := reemplazaAuxiliarContable(chara11);  
        // if chara11[13] = '&' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '@' then
          chara11 := copy(chara11, 1, 12) + '001';
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        if mt_comision_ext > 0.01 then
          graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);

      end;

      final9 := dmvar.final;
      adiciona9 := dmvar.adicional;
      personacnv9 := dmvar13.personacnv;
      if dmvar13.swCostosLiquida then //Solicitud Interbursa
      begin
        DMpapel.TBfinal.IndexName := DMvar.IDfin[0];
        DMpapel.TBfinal.findkey(['BVC000']);
        Carga_final(DMpapel.TBfinal);
        DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
        Carga_adiciona(DMpapel.TBadiciona);
        DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
        carga_personacnv(DMpapel.TBtpersonacnv);
      end;


      if tp_concepto = 0 then //quede aqui 28/03/2005
      begin
        monto := mt_neto - mt_comision - mt_ajuste - redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) - mt_comision_ext + CmiBolsa - mt_comision * mt_islr / 100;
        chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') //armo cuenta con datos de la BVC000
          + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004
        chara12 := Busca_auxcliente(dmvar13.swAuxCliLiq, dmvar2.bolsa.tp_concepto);
        if (chara11[13] = '&') then
          if (dmvar2.bolsa.tp_concepto <> 5) then
          begin
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
            chara12 := dmvar.final.co_final;
          end
          else if trim(dmvar13.coAuxClienteCruce) = '' then
          begin
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
            chara12 := dmvar.final.co_final;
          end
          else
          begin
            chara11 := copy(chara11, 1, 12) + dmvar13.coAuxClienteCruce;
            chara12 := dmvar13.coAuxClienteCruce;
          end;
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        _observa := observa;
         // Solicitud Interbursa
        if dmvar13.swCostosLiquida then
        begin
          _observa := loper(nu_oper_bolsa) + ' ' + dmvar.final.co_final + copy(display_d(ca_valor, 12, 1), 1, 10);
          dmvar.final := final9;
          dmvar.adicional := adiciona9;
          dmvar13.personacnv := personacnv9;
          _chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004
          ajustacodigo(_chara11, _chara12);

          // Jfiguera esto lo que hace poner la 186 por el debito y el credito pero sin ningun efecto real, puro relleno
          //graba_linea(_chara11,observa,txt('Otras Part. '+dmvar.final.co_final,12),mt_neto,DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);
          //graba_linea(_chara11,observa,txt('Otras Part. '+dmvar.final.co_final,12),mt_neto,DMvar2.bolsa.mt_tasa_cambio, not tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);


          final9 := dmvar.final;
          adiciona9 := dmvar.adicional;
          personacnv9 := dmvar13.personacnv;

          if dmvar2.bolsa.tp_concepto = 5 then
          begin
            crucepropia := false;
            auxasigna := DMvar2.asignacion;
            DMpapel.tbfinalaux.Open;
            DMpapel.tbfinalaux.IndexName := DMvar.IDfin[2];
            DMpapel.TBauxasigna.Open;
            DMpapel.TBauxasigna.IndexName := dmvar.IDasi[0];
            DMpapel.TBauxasigna.cancelrange;
            DMpapel.TBauxasigna.setrange([DMvar2.bolsa.nu_oper_bolsa], [DMvar2.bolsa.nu_oper_bolsa]);
            DMpapel.TBauxasigna.first;
            while (not DMpapel.TBauxasigna.eof) and (not crucepropia) do
            begin
              carga_asigna(DMpapel.TBauxasigna);
              if DMvar2.asignacion.sw_del = 0 then
              begin
                DMpapel.tbfinalaux.FindKey([DMvar2.asignacion.nu_cliente]);
                if DMpapel.tbfinalaux.FieldByName('tp_cliente').AsString = 'P' then
                begin
                  asignapropia := DMvar2.asignacion;
                  crucepropia := True;
                  Break;
                end;
              end;
              DMpapel.TBauxasigna.next;
            end;
            DMvar2.asignacion := auxasigna;

            if crucepropia then
            begin
//              monto1 := (asignapropia.ca_valor * dmvar2.bolsa.mt_comision1 / dmvar2.bolsa.ca_valor) + (asignapropia.ca_valor * asignapropia.mt_valor * asignapropia.mt_islr / 100);

              monto1 := asignapropia.ca_valor * asignapropia.mt_valor + dmvar2.bolsa.mt_comision1 / 2;
//              monto1 := (asignapropia.ca_valor * asignapropia.mt_valor)-(asignapropia.ca_valor * dmvar2.bolsa.mt_comision1 / dmvar2.bolsa.ca_valor) + (asignapropia.ca_valor * asignapropia.mt_valor * asignapropia.mt_islr / 100);
              graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto1, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
            end
            else
              graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), ca_valor * (dmvar2.bolsa.mt_comision1 / 2) / dmvar2.bolsa.ca_valor, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
          end
          else //lo activamos porque descuadra el asiento si esta comentariado. Faltar�a cta x pagar bolsa 14/02/2006
            graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);

          DMpapel.tbfinalaux.Close;
          DMpapel.TBauxasigna.Close;
        end
        else
          graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);

        str(monto: 18: 2, txtmonto);
        lista1.Add(nu_oper_bolsa + txt(chara12, 6) + txtmonto);
        if mt_islr > 0 then
        begin
          chara11 := arma_cuenta('ISLR', true, true, dmvar.titulo.nu_moneda, 1, 'C');
          graba_linea(chara11, observa, txt('ISLR. ' + dmvar.final.co_final, 12), mt_comision * mt_islr / 100, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '15', ' ', loper(nu_oper_bolsa), 0);
        end;
      end
      else
      begin //venta

        monto := mt_neto + mt_comision + mt_ajuste + redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) + mt_comision_ext - CmiBolsa;
//					chara11 := arma_cuenta('OPartC',true,true,dmvar.titulo.nu_moneda,1,'C')
//             			+Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas,dmvar2.bolsa.tp_concepto);   //ces 13/10/2004
          // Jfiguera  7556 ahora la cuenta con venta pero con cruce tiene que agarrar la cuenta contable de venta para todo el mundo
        chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004

        chara12 := Busca_auxcliente(dmvar13.swAuxCliLiq, dmvar2.bolsa.tp_concepto);
        if (chara11[13] = '&') then
          if (dmvar2.bolsa.tp_concepto <> 5) then
          begin
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
            chara12 := dmvar.final.co_final;
          end
          else if trim(dmvar13.coAuxClienteCruce) = '' then
          begin
            chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
            chara12 := dmvar.final.co_final;
          end
          else
          begin
            chara11 := copy(chara11, 1, 12) + dmvar13.coAuxClienteCruce;
            chara12 := dmvar13.coAuxClienteCruce;
          end;

        _observa := observa;
        _observa := loper(nu_oper_bolsa) + ' ' + dmvar.final.co_final + copy(display_d(ca_valor, 12, 1), 1, 10);
        // if chara11[13] = '#' then
        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
        if chara11[13] = '-' then
          chara11 := copy(chara11, 1, 12);
        if chara11[13] = '%' then
          chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
        str(monto: 18: 2, txtmonto);
        lista1.Add(nu_oper_bolsa + txt(chara12, 6) + txtmonto);
        if dmvar2.bolsa.tp_concepto = 5 then//venta y cruce. Cuentas por pagar bolsa
        begin
          if dmvar13.swCostosLiquida then //interbursa
          begin
           //esto estaba descuadrando el asiento. Lo comentari� ya que el asiento de BNH de la gorda salia mal     //ces 16/02/2007
            dmvar.final := final9;
            dmvar.adicional := adiciona9;
            dmvar13.personacnv := personacnv9;

            _chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004


            ajustacodigo(_chara11, _chara12);
            // Jfiguera 27-07-2023
           (* if (dmvar2.calendario1.nu_corredor <> 72) then   // Jfiguera 7711 se a�adio el corredor SIGO SIN SABER POR QUE NO FALLA PARA TODOS!
            begin
              graba_linea(_chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), mt_neto, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
              graba_linea(_chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), mt_neto, {1}DMvar2.bolsa.mt_tasa_cambio, not (tp_concepto = 0), observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
            end; *)
            final9 := dmvar.final;
            adiciona9 := dmvar.adicional;
            personacnv9 := dmvar13.personacnv;
                            //Vanessa 24/10 cuando es cruce el gasto de la bolsa se debe dividir entre las 2 operaciones

            crucepropia := false;
            auxasigna := DMvar2.asignacion;
            DMpapel.tbfinalaux.Open;
            DMpapel.tbfinalaux.IndexName := DMvar.IDfin[2];
            DMpapel.TBauxasigna.Open;
            DMpapel.TBauxasigna.IndexName := dmvar.IDasi[0];
            DMpapel.TBauxasigna.cancelrange;
            DMpapel.TBauxasigna.setrange([DMvar2.bolsa.nu_oper_bolsa], [DMvar2.bolsa.nu_oper_bolsa]);
            DMpapel.TBauxasigna.first;
            while (not DMpapel.TBauxasigna.eof) and (not crucepropia) do
            begin
              carga_asigna(DMpapel.TBauxasigna);
              if DMvar2.asignacion.sw_del = 0 then
              begin
                DMpapel.tbfinalaux.FindKey([DMvar2.asignacion.nu_cliente]);
                if DMpapel.tbfinalaux.FieldByName('tp_cliente').AsString = 'P' then
                begin
                  asignapropia := DMvar2.asignacion;
                  crucepropia := True;
                  Break;
                end;
              end;
              DMpapel.TBauxasigna.next;
            end;
            DMvar2.asignacion := auxasigna;

            if crucepropia then
            begin
              monto1 := dmvar2.asignacion.mt_valor * dmvar2.asignacion.ca_valor - (mt_islr * dmvar2.asignacion.mt_valor * dmvar2.asignacion.ca_valor / 100) - mt_comision_bolsa;
//                       ((asignapropia.ca_valor * dmvar2.bolsa.mt_comision1 / dmvar2.bolsa.ca_valor) + (ca_valor * mt_valor * mt_islr / 100));
              graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto1, {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
            end
            else
            begin
              monto := ca_valor * (dmvar2.bolsa.mt_comision1 / 2) / dmvar2.bolsa.ca_valor + mt_islr * ca_valor * mt_valor / 100;
              graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), {ca_valor*dmvar2.bolsa.mt_comision1/dmvar2.bolsa.ca_valor+
                              mt_islr*ca_valor*mt_valor/100}monto, {1}DMvar2.bolsa.mt_tasa_cambio, true, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
            end;

          end
          else
            graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), loper(nu_oper_bolsa), 0);
        end
        else //venta y no cruce. Cuentas por cobrar bolsa
        begin
          chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidasV, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004

//							+Busca_auxcliente(dmvar13.swAuxCliCon,dmvar2.bolsa.tp_concepto);
//							+Busca_auxcliente(dmvar13.swAuxCliLiq,dmvar2.bolsa.tp_concepto);
          if (chara11[13] = '&') then
            if (dmvar2.bolsa.tp_concepto <> 5) then
              chara11 := copy(chara11, 1, 12) + dmvar.final.co_final
            else
              chara11 := copy(chara11, 1, 12) + dmvar13.coAuxClienteCruce;
          // if chara11[13] = '#' then
          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
          if chara11[13] = '-' then
            chara11 := copy(chara11, 1, 12);
          if chara11[13] = '%' then
            chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);
          if dmvar13.swCostosLiquida then
          begin
                 //esto estaba descuadrando el asiento. Lo comentari� ya que el asiento de BNH de la gorda salia mal     //ces 16/02/2007
            dmvar.final := final9;
            dmvar.adicional := adiciona9;
            dmvar13.personacnv := personacnv9;
            _chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004
            ajustacodigo(_chara11, _chara12);
            graba_linea(_chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), mt_neto, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 1, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);
            graba_linea(_chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), mt_neto, {1}DMvar2.bolsa.mt_tasa_cambio, not tp_concepto = 1, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);
            final9 := dmvar.final;
            adiciona9 := dmvar.adicional;
            personacnv9 := dmvar13.personacnv;

          end;
          graba_linea(chara11, _observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, {1}DMvar2.bolsa.mt_tasa_cambio, tp_concepto = 0, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);
        end;
      end;
      dmvar.final := final9;
      dmvar.adicional := adiciona9;
      dmvar13.personacnv := personacnv9;
   // Solicitud Interbursa
      if dmvar13.swCostosLiquida then
        if dmvar2.asignacion.mt_comision + dmvar2.asignacion.mt_ajuste > 0.01 then
          if fl_transac <> fl_fuera then  //solo para transacciones spot   //Caso 1026 //ces 01/06/2016
            genera_cmi_cli;

            // Jfiguera 8717 - 18-02-2021     Tiene pinta que voy a da�ar algo
      if not dmvar13.swCostosLiquida then
        if mt_iva_esp > 0 then
        begin
//      if mt_comision + mt_ajuste > 0 then   // Jfiguera a�adido if
//        graba_linea(arma_cuenta('IvaAct', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), 1, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '92', ' ', loper(nu_oper_bolsa), 0);
          if mt_isv_comision > 0 then      // Jfiguera a�adido if
          begin
            if (pos('MERCOSUR', uppercase(dmvar.calendario.tx_dominio)) > 0) then

              if dmvar2.asignacion.fl_efectivo_neto = flch_a_jul(txtdesde.text) then
                graba_linea(arma_cuenta('IvaOtr', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '92', ' ', loper(nu_oper_bolsa), 0)
              else
                graba_linea(arma_cuenta('IvaAct', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '92', ' ', loper(nu_oper_bolsa), 0)
            else
              graba_linea(arma_cuenta('IvaAct', tp_concepto = 1, true, dmvar.titulo.nu_moneda, 1, 'C'){+Busca_AuxCliente(dmvar13.swAuxCliCon)}, observa, ceros(lintstr(nu_asignacion, 8)), redondea(mt_isv_comision * mt_iva_esp / 100, 2), {1}DMvar2.bolsa.mt_tasa_cambio, false, observa1, observa2, 'A' + nu_oper_bolsa, lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '92', ' ', loper(nu_oper_bolsa), 0);
          end;
        end;
   //
      cant1 := 1;
      if dmvar.titulo.sw_f_v_u_o = 'P' then
        cant1 := 100;
      EfectivoCli := ca_valor * mt_valor / cant1;
      if (tp_concepto = 0) and (dmvar.final.tp_cliente = 'P') then
        EfectivoCli := dmvar2.asignacion.mt_neto;
      if dmvar2.asignacion.fl_transac <> dmvar2.asignacion.fl_fuera then //reversa contingencia si la fecha es diferente
        genera_reverso_derecho_cli('A' + nu_oper_bolsa);
//			if valora(co_cta_custodia) then
//        if (DMvar2.calendario1.nu_corredor <> 40) and (DMvar2.calendario1.nu_corredor <> 32) then
//  				GeneraMutuoPasivo('A'+nu_oper_bolsa);


    end;
    dmvar.pabo := pabo9;
  end;

  procedure Liquida_Neto;

    procedure genera_reverso_cruces(observa, observa1, txclave: string);
    var
      cliente9: clientes;
      adiciona9: adicionales;
      persona9: personacnvs;
      auxcliente, chara11: string;
      monto1, cant1: double;
      auxilioActivalores, CmiBolsa: double;
      auxclientecc: string;
    begin

      cliente9 := dmvar.final;
      adiciona9 := dmvar.adicional;
      persona9 := dmvar13.personacnv;
      dmpapel.tbasigna.indexname := dmvar.IDasi[0];
      dmpapel.tbasigna.setrange([dmvar2.bolsa.nu_oper_bolsa], [dmvar2.bolsa.nu_oper_bolsa]);
      dmpapel.tbasigna.first;
      auxclientecc := '';
      while (not dmpapel.tbasigna.eof) do
        with dmvar2.asignacion do
        begin
          carga_asigna(dmpapel.tbasigna);
          if sw_del = 0 then
          begin
            busca_titulo(co_valor);
            cant1 := 1;
            if dmvar.titulo.sw_f_v_u_o = 'P' then
              cant1 := 100;

            auxilioActivalores := 0;
            if (pos('ACTIVALORES', uppercase(dmvar.calendario.tx_dominio)) > 0) then     // Jfiguera
              auxilioActivalores := dmvar2.asignacion.MT_COMISION_BOLSA;

            DMpapel.TBfinal.IndexName := DMvar.IDfin[2];
            DMpapel.TBfinal.findkey([nu_cliente]);
            Carga_final(DMpapel.TBfinal);
            dmpapel.tbadiciona.indexname := dmvar.idadi[0];
            DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
            Carga_adiciona(DMpapel.TBadiciona);
            DMpapel.TBtpersonacnv.cancelrange;
            DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
            carga_personacnv(DMpapel.TBtpersonacnv);
            auxcliente := Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, dmvar2.bolsa.tp_concepto);   //ces 13/10/2004

            if DMVAR2.ASIGNACION.tp_concepto = 0 then            // Jfiguera  7712 a�adi el if, siempre armaba con la cuenta de compra
            begin
              chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + auxcliente;
            end
            else
              chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + auxcliente;

            if (chara11[13] = '&') then
              if trim(dmvar13.coauxclientecruce) = '' then
                chara11 := copy(chara11, 1, 12) + Busca_auxcliente(dmvar13.swAuxCliLiq, dmvar2.bolsa.tp_concepto)
              else
                chara11 := copy(chara11, 1, 12) + dmvar13.coauxclientecruce;
            // if chara11[13] = '#' then
            //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
            if chara11[13] = '-' then
              chara11 := copy(chara11, 1, 12);
            if chara11[13] = '%' then
              chara11 := copy(chara11, 1, 12) + trim(busca_auxtitulo);

            if fl_transac <> fl_fuera then
                if mt_comision_bolsa > 0.01 then
                  CmiBolsa := 0
                else
                  CmiBolsa := ca_valor * dmvar2.bolsa.mt_comision1 / dmvar2.bolsa.ca_valor;

            with dmvar2.asignacion do
              if dmvar.final.tp_cliente = 'P' then
                if mt_comision_bolsa = 0 then
                  if tp_concepto = 0 then
                    monto1 := mt_neto + dmvar2.bolsa.mt_comision1 - mt_comision_ext
                  else
                    monto1 := mt_neto - dmvar2.bolsa.mt_comision1 + mt_comision_ext
                else
                  monto1 := mt_neto
              else if tp_concepto = 0 then
              begin
                monto1 := (ca_valor * mt_valor / cant1 + dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor + dmvar2.bolsa.mt_interes * ca_valor / dmvar2.bolsa.ca_valor) - auxilioActivalores;


                if dmvar2.calendario1.nu_corredor = 77 then
                  monto1 := mt_neto - mt_comision - mt_ajuste - redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) - mt_comision_ext + CmiBolsa - mt_comision * mt_islr / 100;
              end
              else
              begin
//                monto1 :=  mt_neto + mt_comision + mt_ajuste +
//                  redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) + mt_comision_ext - CmiBolsa + auxilioActivalores;
//                if not dmvar13.swseparariva then
//                  if fl_transac = fl_fuera then
//                    monto1 := (ca_valor * mt_valor / cant1 - (dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor) + dmvar2.bolsa.mt_interes * ca_valor / dmvar2.bolsa.ca_valor - ca_valor * mt_valor / cant1 * dmvar2.bolsa.mt_islr / 100) + auxilioActivalores
//                  else
                    monto1 :=  mt_neto + mt_comision + mt_ajuste +
                              redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) + mt_comision_ext - CmiBolsa + auxilioActivalores;
              end;




          //Solicitud de interbursa
            if dmvar13.swCostosLiquida then
              if tp_concepto = 0 then
                monto1 := dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor
              else
                monto1 := dmvar2.bolsa.mt_comision1 * ca_valor / dmvar2.bolsa.ca_valor + mt_islr;
            if dmvar13.swCostosLiquida then                                         //true estaba en true 21/02/2007
              graba_linea(chara11, observa, txt(dmvar.pabo.nu_deposito, 12), abs(monto1), dmvar2.bolsa.mt_tasa_cambio, false, observa1,  //cambio de referencia ces 04/10/2004
                dmvar.final.co_final, 'N' + ceros(lintstr(dmvar2.neto.nu_neto, 8)), '0' + lintstr(dmvar.correspo.nu_moneda, 1) + txclave, dmvar.pabo.nu_deposito, loper(dmvar2.bolsa.nu_oper_bolsa), dmvar.pabo.nu_correspo)
            else
              graba_linea(chara11, observa, txt(dmvar.pabo.nu_deposito, 12), abs(monto1), dmvar2.bolsa.mt_tasa_cambio, dmvar2.asignacion.tp_concepto = 1, observa1,  //cambio de referencia ces 04/10/2004
                dmvar.final.co_final, 'N' + ceros(lintstr(dmvar2.neto.nu_neto, 8)), '0' + lintstr(dmvar.correspo.nu_moneda, 1) + txclave, dmvar.pabo.nu_deposito, loper(dmvar2.bolsa.nu_oper_bolsa), dmvar.pabo.nu_correspo);
          end;
          dmpapel.tbasigna.next;
        end;
      dmvar.final := cliente9;
      dmvar.adicional := adiciona9;
      dmvar13.personacnv := persona9;
    end;

  var
    existe, existe1, _sw_deb_cre: boolean;
    observa, observa1, observa2, auxcliente, txclave, chara22: string;
    monto, cmibolsa, montolista, monto1: double;
    tpconcepto, i: integer;
    adiciona9: adicionales;
    personacnv9: personacnvs;
  begin
    dmpapel.tbnetos.IndexName := DMvar.IDnet[2];
    dmpapel.tbnetos.SetRange([flch_a_jul(TXTdesde.text)], [flch_a_jul(TXTdesde.text)]);
    dmpapel.tbnetos.first;
    while (not dmpapel.tbnetos.eof) do
      with dmvar2.neto do
      begin
        existe := false;
        carga_netos(dmpapel.tbnetos);
        if not sw_del then
        begin
          DMpapel.TBfinal.IndexName := DMvar.IDfin[2];
          DMpapel.TBfinal.findkey([nu_cliente]);
          Carga_final(DMpapel.TBfinal);
          if dmvar.final.co_final = 'BVC000' then
            CliBolsa := dmvar.final.nu_final;
          dmpapel.tbadiciona.indexname := dmvar.idadi[0];
          DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
          Carga_adiciona(DMpapel.TBadiciona);
          DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
          carga_personacnv(DMpapel.TBtpersonacnv);
          personacnv9 := dmvar13.personacnv;
//      if existe then
          begin
            monto := 0;
            DMpapel.tbpaso.indexname := dmvar.IDpas[4];
            DMpapel.tbpaso.setrange([origen_bolsa + ceros(lintstr(dmvar2.neto.nu_neto, 11))], [origen_bolsa + ceros(lintstr(dmvar2.neto.nu_neto, 11))]);
            DMpapel.tbpaso.first;
            while (not DMpapel.tbpaso.eof) do
            begin
              carga_paso(DMpapel.tbpaso);
              if dmvar.pabo.mt_paso > 0.01 then
              begin
                if dmvar.final.co_final = 'BVC000' then
                  txclave := '11'
                else
                  txclave := '14';
                if dmvar.pabo.tp_paso = 'I' then
                  monto := monto + dmvar.pabo.mt_paso
                else
                  monto := monto - dmvar.pabo.mt_paso;
                observa1 := ' ' + dmvar.final.co_final;
                dmpapel.tbcorre.FindKey([dmvar.pabo.nu_correspo]);
                carga_correspo(dmpapel.tbcorre);
                observa := 'Liqui.' + jul_a_flch(dmvar.pabo.fl_disp) + ' Neto #' + ceros(lintstr(nu_neto, 6)); // ces 15/10/2003
                observa2 := txt(' ', 13) + ceros(lintstr(dmvar.pabo.tp_pago, 2));
                graba_linea(dmvar.correspo.co_contable, observa,
                  txt(dmvar.pabo.nu_deposito, 12), abs(dmvar.pabo.mt_paso), 1, //cambio de referencia ces 04/10/2004
                  dmvar.pabo.tp_paso = 'E', observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), '0' + lintstr(dmvar.correspo.nu_moneda, 1) + txclave, dmvar.pabo.nu_deposito, ' ', dmvar.pabo.nu_correspo);
              end;
              DMpapel.tbpaso.next;
            end;
            dmpapel.tbdnetos.IndexName := dmvar.iddne[0];
            dmpapel.tbdnetos.setrange([nu_neto], [nu_neto]);
            dmpapel.tbdnetos.First;
            while (not dmpapel.tbdnetos.eof) do
            begin
              carga_dnetos(dmpapel.tbdnetos);
              observa := 'Liqui.' + loper(dmvar2.dneto.nu_oper_bolsa) + ' ' + txtdesde.text;
              observa1 := ' Neto #' + ceros(lintstr(nu_neto, 5)) + ' ';
              dmpapel.tbbolsa.indexname := dmvar.IDbol[0];
//					dmpapel.tbbolsa.findkey([dmvar2.dneto.nu_oper_bolsa,0]);       // Jfiguera viejo 11-03-2020

          // Jfiguera 11-03-2020 ini nuevo por setrange
              dmpapel.tbbolsa.SetRange([dmvar2.dneto.nu_oper_bolsa, 0], [dmvar2.dneto.nu_oper_bolsa, 0]);
              dmpapel.tbbolsa.First;
              while not dmpapel.tbbolsa.eof do
              begin
                carga_bolsa(dmpapel.tbbolsa);
                if DMvar2.bolsa.fl_transac = flch_a_jul(TXTdesde.text) then
                begin
                  Break;
                end;
                dmpapel.tbbolsa.next;
              end;
          // Jfiguera fin


              DMpapel.TBtitulo.indexname := DMvar.IDtit[1];
              DMpapel.TBtitulo.findkey([DMvar2.bolsa.co_valor]);
              Carga_titulo(DMpapel.TBtitulo);
              frmpapel.BuscarNumeroPos(dmvar.titulo.sw_f_v_u_o, dmvar.numero_pos); //21/01/2004
              DMpapel.TBtptcontcnv.findkey([DMvar.titulo.co_tipo, 98, dmvar.numero_pos]); //vehiculo,cartera
              Carga_tptcontcnv(DMpapel.TBtptcontcnv);
              auxcliente := '';
              if dmvar.final.co_final = 'BVC000' then
              begin
                cliente9 := dmvar.final;
                adiciona9 := dmvar.adicional;
                personacnv9 := dmvar13.personacnv;
                if dmvar13.swAuxCli < 3 then
                  for i := 0 to lista1.Count - 1 do
                  begin
                    busca_cliente(copy(lista1.strings[i], 12, 6), 0, '', 0);
                    val(copy(lista1.strings[i], 18, 18), montolista, errorcode);
                    if dmvar2.dneto.nu_oper_bolsa = copy(lista1.Strings[i], 1, 11) then
                      if (abs(abs(dmvar2.dneto.mt_neto) - abs(montolista)) < 0.01) then
                      begin
                        auxcliente := copy(lista1.strings[i], 12, 6);
                        break;
                      end;
                  end;
                (*if (dmvar2.bolsa.tp_concepto = 1) then
                begin
                if dmvar13.swAuxCli < 3 then
                  begin
                    if auxcliente = '' then
                    begin
                      if BuscaCliAsigna(dmvar2.bolsa.nu_oper_bolsa) > 0 then
                        busca_cliente('', dmvar2.asignacion.nu_cliente, '', 2);
                      auxcliente := Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidasV, 1);
                    end;
                    DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
                    carga_personacnv(DMpapel.TBtpersonacnv);
                  end;
                  chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + auxcliente;
                  if (dmvar2.calendario1.nu_corredor = 61) then
                    chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000';
                  if (chara11[13] = '&') then
                    if (dmvar2.bolsa.tp_concepto <> 5) then
                      chara11 := copy(chara11, 1, 12) + auxcliente
                    else
                      chara11 := copy(chara11, 1, 12) + dmvar13.coAuxClienteCruce;
                  if chara11[13] = '#' then
                    chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                  if chara11[13] = '-' then
                    chara11 := copy(chara11, 1, 12);
                  graba_linea(chara11,observa,txt(dmvar.pabo.nu_deposito, 12), abs(dmvar2.dneto.mt_neto),1,dmvar2.dneto.mt_neto < 0, observa1,  //cambio de referencia ces 04/10/2004
                    dmvar.final.co_final,'N'+ceros(lintstr(nu_neto, 8)),'0'+lintstr(dmvar.correspo.nu_moneda,1)+txclave,dmvar.pabo.nu_deposito,loper(dmvar2.bolsa.nu_oper_bolsa),dmvar.pabo.nu_correspo)
                end
                else //compra o cruce
                begin
                  if dmvar2.bolsa.tp_concepto = 5 then
                    auxcliente := Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, 0);
                  if dmvar13.swAuxCli < 3 then
                  begin
                    if auxcliente = '' then
                    begin
                      if BuscaCliAsigna(dmvar2.bolsa.nu_oper_bolsa) > 0 then
                        busca_cliente('', dmvar2.asignacion.nu_cliente, '', 2);
                      auxcliente := Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, 1);   //ces 13/10/2004
                    end;
                    DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
                    carga_personacnv(DMpapel.TBtpersonacnv);
                  end;

                  if dmvar2.asignacion.TP_CONCEPTO = 0 then    // Jfiguera 7711 Hayque buscar la asignacion para saber si es compra o vernta
                    chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + auxcliente
                  else
                    chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C');

                  if (dmvar2.calendario1.nu_corredor = 61) {or (dmvar2.calendario1.nu_corredor = 10)} then
                    chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000';
                  if (chara11[13] = '&') then
                    if (dmvar2.bolsa.tp_concepto <> 5) then
                      chara11 := copy(chara11, 1, 12) + auxcliente
                    else
                      chara11 := copy(chara11, 1, 12) + dmvar13.coauxclientecruce;
                  if chara11[13] = '#' then
                    chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                  if chara11[13] = '-' then
                    chara11 := copy(chara11, 1, 12);
                  _sw_deb_cre := dmvar2.dneto.mt_neto < 0;
                  if dmvar2.bolsa.tp_concepto = 5 then
                    _sw_deb_cre := false;
//							if ((dmvar2.bolsa.tp_concepto = 5) and (not dmvar13.swAuxCliLiq)) or                           // lo quite porque no me parecio que tuviera sentido para hacer el reverso de otras partidas en los cruces 21/02/2007
//										(dmvar2.bolsa.tp_concepto <> 5) then  //reversos de otras partidas contables sin auxiliar   // lo quite porque no me parecio que tuviera sentido para hacer el reverso de otras partidas en los cruces 21/02/2007
                  if (pos('ACTIVALORES', uppercase(dmvar.calendario.tx_dominio)) = 0) or                                                // Jfiguera  7712 ESTO ESTABA COMENTADO, SE QUITA Y SE PONE A CADA RATO! HAY QUE VER BIEN EL CASO DE ACTIVALORES
                    ((pos('ACTIVALORES', uppercase(dmvar.calendario.tx_dominio)) > 0) and (dmvar2.asignacion.TP_CONCEPTO = 0)) then  // Jfiguera 8058 OTRA VEZ EL PEO CON ACTIVALORES!!!! HAY QUE REVISARRRRRRRRRR
                  begin
                    if DMvar2.calendario1.nu_corredor <> 77 then
                    begin
                      graba_linea(chara11, observa,
                        txt(dmvar.pabo.nu_deposito, 12), abs(dmvar2.dneto.mt_neto), 1, _sw_deb_cre, observa1, //cambio de referencia ces 04/10/2004
                        dmvar.final.co_final, 'N' + ceros(lintstr(nu_neto, 8)), '0' + lintstr(dmvar.correspo.nu_moneda, 1) + txclave, dmvar.pabo.nu_deposito, loper(dmvar2.bolsa.nu_oper_bolsa), dmvar.pabo.nu_correspo);
                    end;
                  end;
                  //if dmvar2.bolsa.tp_concepto in [5, 0] then
                  if dmvar2.bolsa.tp_concepto = 5 then
                    if dmvar13.swAuxCli < 3 then
                      if dmvar13.swAuxClicon then  //reversos de otras partidas contables con auxiliar
                        if (dmvar2.calendario1.nu_corredor <> 61) and (dmvar2.calendario1.nu_corredor <> 10) and (dmvar2.calendario1.nu_corredor <> 49) and   //Jorge 28/12/2017
                          (dmvar2.calendario1.nu_corredor <> 68) and   //Jorge 28/12/2017
                          (dmvar2.calendario1.nu_corredor <> 48) and // Jfiguera A�ADIDO EL 48 // BNH. LA GORDA //si lo genera, descuadra el asiento con �stos par�metros ces 13/02/2007
                          (DMvar2.calendario1.nu_corredor <> 66) and    //CES 13/05/2019
                          (DMvar2.calendario1.nu_corredor <> 32) and    //CES 13/05/2019
                          (dmvar2.calendario1.nu_corredor <> 64) then // Jfiguera A�ADIDO EL 77 // BNH. LA GORDA //si lo genera, descuadra el asiento con �stos par�metros ces 13/02/2007
                          genera_reverso_cruces(observa, observa1, txclave);
                end;    *)

                //Vanessa 14/06/2023 casos 13246 / 13247
                dmvar.final := cliente9;
                dmvar.adicional := adiciona9;
                dmvar13.personacnv := personacnv9;
                dmpapel.tbasigna.indexname := dmvar.IDasi[0];
                dmpapel.tbasigna.setrange([dmvar2.bolsa.nu_oper_bolsa], [dmvar2.bolsa.nu_oper_bolsa]);
                dmpapel.tbasigna.first;
                while (not dmpapel.tbasigna.eof) do
                with dmvar2.asignacion do
                begin
                  carga_asigna(dmpapel.tbasigna);
                  if sw_del = 0 then
                  begin
                    DMpapel.TBfinal.IndexName := DMvar.IDfin[2];
                    DMpapel.TBfinal.findkey([nu_cliente]);
                    Carga_final(DMpapel.TBfinal);
                    dmpapel.tbadiciona.indexname := dmvar.idadi[0];
                    DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
                    Carga_adiciona(DMpapel.TBadiciona);

                    if dmvar2.bolsa.tp_concepto = 5 then
                      auxcliente := Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, 0);
                    if dmvar13.swAuxCli < 3 then
                    begin
                      if auxcliente = '' then
                      begin
                        if BuscaCliAsigna(dmvar2.bolsa.nu_oper_bolsa) > 0 then
                          busca_cliente('', dmvar2.asignacion.nu_cliente, '', 2);
                        auxcliente := Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, 1);   //ces 13/10/2004
                      end;
                      DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
                      carga_personacnv(DMpapel.TBtpersonacnv);
                    end;

                    if dmvar2.asignacion.TP_CONCEPTO = 0 then    // Jfiguera 7711 Hayque buscar la asignacion para saber si es compra o vernta
                      chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + auxcliente
                    else
                      chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C');

                    if (dmvar2.calendario1.nu_corredor = 61) {or (dmvar2.calendario1.nu_corredor = 10)} then
                      chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + 'BVC000';
                    if (chara11[13] = '&') then
                      if (dmvar2.bolsa.tp_concepto <> 5) then
                        chara11 := copy(chara11, 1, 12) + auxcliente
                      else
                        chara11 := copy(chara11, 1, 12) + dmvar13.coauxclientecruce;
                    // if chara11[13] = '#' then
                    //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                    if chara11[13] = '-' then
                      chara11 := copy(chara11, 1, 12);

                    if dmvar.final.tp_cliente = 'P' then
                      monto := DMvar2.asignacion.mt_neto
                    else
                    if DMvar2.asignacion.tp_concepto = 0 then
                       monto := DMvar2.asignacion.mt_neto-DMvar2.asignacion.mt_comision-(DMvar2.asignacion.mt_isv_comision)
                                                         + (DMvar2.asignacion.mt_isv_comision * DMvar2.asignacion.mt_iva_esp /100)

                    else monto := DMvar2.asignacion.mt_neto+DMvar2.asignacion.mt_comision+DMvar2.asignacion.mt_isv_comision
                                                          -(DMvar2.asignacion.mt_isv_comision * DMvar2.asignacion.mt_iva_esp /100);
                    graba_linea(chara11,observa,txt(dmvar.pabo.nu_deposito,12),abs(monto),dmvar2.bolsa.mt_tasa_cambio,DMvar2.asignacion.tp_concepto = 1,observa1,
                                dmvar.final.co_final,'N'+ceros(lintstr(nu_neto,8)),'0'+lintstr(dmvar.correspo.nu_moneda,1)+txclave,dmvar.pabo.nu_deposito,
                                loper(dmvar2.bolsa.nu_oper_bolsa),dmvar.pabo.nu_correspo);
                  end;
                  dmpapel.tbasigna.next;
                end;
                dmvar.final := cliente9;


                if dmvar2.bolsa.tp_concepto = 5 then
                  if dmvar13.swAuxCli < 3 then
                    if dmvar13.swAuxClicon then  //reversos de otras partidas contables con auxiliar
                      if (dmvar2.calendario1.nu_corredor <> 61) and (dmvar2.calendario1.nu_corredor <> 10) and (dmvar2.calendario1.nu_corredor <> 49) and   //Jorge 28/12/2017
                        (dmvar2.calendario1.nu_corredor <> 68) and   //Jorge 28/12/2017
                        (dmvar2.calendario1.nu_corredor <> 48) and // Jfiguera A�ADIDO EL 48 // BNH. LA GORDA //si lo genera, descuadra el asiento con �stos par�metros ces 13/02/2007
                        (DMvar2.calendario1.nu_corredor <> 66) and    //CES 13/05/2019
                        (DMvar2.calendario1.nu_corredor <> 32) and    //CES 13/05/2019
                        (dmvar2.calendario1.nu_corredor <> 64) then // Jfiguera A�ADIDO EL 77 // BNH. LA GORDA //si lo genera, descuadra el asiento con �stos par�metros ces 13/02/2007
                        genera_reverso_cruces(observa, observa1, txclave);
                //Fin Vanessa 14/06/2023 casos 13246 / 13247

                dmvar.final := cliente9;
                dmvar.adicional := adiciona9;
                dmvar13.personacnv := personacnv9;
                dmpapel.tbasigna.indexname := dmvar.IDasi[0];
                dmpapel.tbasigna.setrange([dmvar2.bolsa.nu_oper_bolsa], [dmvar2.bolsa.nu_oper_bolsa]);
                dmpapel.tbasigna.first;
                while (not dmpapel.tbasigna.eof) do
                  with dmvar2.asignacion do
                  begin
                    carga_asigna(dmpapel.tbasigna);
                    if sw_del = 0 then
                      if fl_transac <> fl_fuera then //Caso 1026 misma fecha no genero contingencia por lo tanto no se debe reversar //ces 01/06/2016
                      begin
                        DMpapel.TBfinal.IndexName := DMvar.IDfin[2];
                        DMpapel.TBfinal.findkey([nu_cliente]);
                        Carga_final(DMpapel.TBfinal);
                        dmpapel.tbadiciona.indexname := dmvar.idadi[0];
                        DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
                        Carga_adiciona(DMpapel.TBadiciona);
                        genera_reverso_derecho_bol('N' + ceros(lintstr(nu_neto, 8)), tp_concepto);
                      end;
                    dmpapel.tbasigna.next;
                  end;
                dmvar.final := cliente9;
              end //BVC000
              else
              begin
                dmpapel.tbasigna.indexname := dmvar.IDasi[0];
                dmpapel.tbasigna.setrange([dmvar2.bolsa.nu_oper_bolsa], [dmvar2.bolsa.nu_oper_bolsa]);
                dmpapel.tbasigna.first;
                existe1 := false;
                while (not dmpapel.tbasigna.eof) and (not existe1) do
                  with dmvar2.asignacion do
                  begin
                    carga_asigna(dmpapel.tbasigna);
                    if sw_del = 0 then
                      if nu_cliente = dmvar2.neto.nu_cliente then
                        existe1 := true;
                    dmpapel.tbasigna.next;
                  end;
                if existe1 then
                  with dmvar2.asignacion do
                  begin
                    cliente9 := dmvar.final;
                    adiciona9 := dmvar.adicional;
                    personacnv9 := dmvar13.personacnv;
                    dmpapel.tbfinal.findkey([dmvar2.asignacion.nu_cliente]);
                    carga_final(dmpapel.tbfinal);
                    dmpapel.tbadiciona.indexname := dmvar.IDadi[0];
                    dmpapel.tbadiciona.findkey([dmvar2.asignacion.nu_cliente]);
                    carga_adiciona(dmpapel.tbadiciona);
                    DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
                    carga_personacnv(DMpapel.TBtpersonacnv);
                    EfectivoCli := ca_valor * mt_valor;
                    if (tp_concepto = 0) and (dmvar.final.tp_cliente = 'P') then
                      EfectivoCli := dmvar2.asignacion.mt_neto;
							//reversos comision
                    if dmvar.final.tp_cliente <> 'P' then
                    begin
                      if tp_concepto = 1 then
                        chara := ' V '
                      else
                        chara := ' C ';
                      observa1 := chara + jul_a_flch(fl_fuera) + ' ' + co_valor;
                      observa2 := txt(display_d(mt_valor, 8, 2) + ' ' + co_cta_custodia, 15);
                      chara11 := trim(arma_cuenta('CmixC', true, true, dmvar.titulo.nu_moneda, 1, 'C')) + Busca_auxcliente(not dmvar13.personacnv.sw_cmi_x_cob, 0);   //ces 23/01/2006
                      if (pos('#-&', chara11) = 0) and (length(chara11) > 12) then

                      else if (dmvar13.swAuxCliCon) and (not dmvar13.personacnv.sw_cmi_x_cob) then //ces 23/01/2006
                        chara11 := arma_cuenta('CmixC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(dmvar13.swAuxCliCon, 0);
                      chara11 := reemplazaAuxiliarContable(chara11);  
                      // if chara11[13] = '&' then
                      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
                      // if chara11[13] = '#' then
                      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                      if chara11[13] = '-' then
                        chara11 := copy(chara11, 1, 12);
                      if chara11[14] = '@' then
                        chara11 := copy(chara11, 1, 13);

                      if mt_comision + mt_ajuste > 0.01 then
                        graba_linea(chara11{arma_cuenta('CmixC',true,true,dmvar.titulo.nu_moneda,1,'C')}, observa, txt('CmixC ' + dmvar.final.co_final, 12), mt_comision + mt_ajuste, 1, true, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);
                      if mt_isv_comision > 0.01 then
                        graba_linea(chara11{arma_cuenta('CmixC',true,true,dmvar.titulo.nu_moneda,1,'C')}, observa, txt('CmixCobrar ' + dmvar.final.co_final, 12), redondea(mt_isv_comision, 2), 1, true, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '09', ' ', loper(nu_oper_bolsa), 0);
								//comision x pagar cvv
                      chara11 := trim(arma_cuenta('CmiCVV', true, true, dmvar.titulo.nu_moneda, 1, 'C'));
                      if (pos('#-&', chara11) = 0) and (length(chara11) > 12) then

                      else
                        chara11 := arma_cuenta('CmiCVV', true, true, dmvar.titulo.nu_moneda, 1, 'C');
                      if chara11[13] = '?' then
                        chara11 := copy(chara11, 1, 12) + 'CVV001';
                      chara11 := reemplazaAuxiliarContable(chara11);  
                      // if chara11[13] = '&' then
                      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
                      // if chara11[13] = '#' then
                      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                      if chara11[13] = '-' then
                        chara11 := copy(chara11, 1, 12);
                      if chara11[14] = '@' then
                        chara11 := copy(chara11, 1, 13);
                      if mt_comision_ext > 0.01 then
                        graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), mt_comision_ext, 1, true, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
                      if mt_comision_bolsa > 0.01 then
                        cmibolsa := 0
                      else
                        cmibolsa := ca_valor * dmvar2.bolsa.mt_comision1 / dmvar2.bolsa.ca_valor;
      // Solicitud Interbursa
      // Si liquida por neto al cliente el iva ya esta incluido en el bloque de liquidacion con neteo ces y na 20/02/2006 panafin
								// reverso comision bolsa
                      chara11 := arma_cuenta('CmiBVC', true, true, dmvar.titulo.nu_moneda, 1, 'C');
                      if chara11[13] = '' then
                        chara11 := arma_cuenta('CmiBVC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(dmvar13.swAuxCliCon, 0);
                      chara11 := reemplazaAuxiliarContable(chara11);  
                      // if chara11[13] = '&' then
                      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
                      // if chara11[13] = '#' then
                      //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                      if chara11[13] = '-' then
                        chara11 := copy(chara11, 1, 12);
                      if mt_comision_bolsa < 0.01 then
                        graba_linea(chara11, observa, txt('Cmi. ' + dmvar.final.co_final, 12), cmibolsa, 1, false, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + '10', ' ', loper(nu_oper_bolsa), 0);
                      if tp_concepto = 0 then
                      begin
                        if dmvar.final.tp_cliente = 'P' then
                          monto := mt_neto - mt_comision - mt_ajuste - redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2){-mt_comision_ext}  + cmibolsa
                        else
                          monto := mt_neto - mt_comision - mt_ajuste - redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) - mt_comision_ext + cmibolsa;
                        chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, tp_concepto);   //ces 13/10/2004
                        chara11 := reemplazaAuxiliarContable(chara11);
                        // if chara11[13] = '&' then
                        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
                        // if chara11[13] = '#' then
                        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                        if chara11[13] = '-' then
                          chara11 := copy(chara11, 1, 12);
                        graba_linea(chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, 1, tp_concepto = 0, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0)
                      end
                      else
                      begin //venta
                        if dmvar.final.tp_cliente = 'P' then
                          monto := mt_neto + mt_comision + mt_ajuste + redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2){+mt_comision_ext}  - cmibolsa
                        else
                          monto := mt_neto + mt_comision + mt_ajuste + redondea((mt_isv_comision - mt_isv_comision * mt_iva_esp / 100), 2) + mt_comision_ext - cmibolsa;
                        chara11 := arma_cuenta('OPartC', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidas, tp_concepto);   //ces 13/10/2004
                        chara11 := reemplazaAuxiliarContable(chara11);
                        // if chara11[13] = '&' then
                        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
                        // if chara11[13] = '#' then
                        //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                        if chara11[13] = '-' then
                          chara11 := copy(chara11, 1, 12);
                        if dmvar2.bolsa.tp_concepto = 5 then//venta y cruce. Cuentas por pagar bolsa
                          graba_linea(chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, 1, tp_concepto = 0, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0)
                        else //venta y no cruce. Cuentas por cobrar bolsa
                        begin
                          chara11 := arma_cuenta('OPartV', true, true, dmvar.titulo.nu_moneda, 1, 'C') + Busca_auxcliente(not dmvar13.personacnv.sw_otras_partidasV, tp_concepto);   //ces 13/10/2004
                          chara11 := reemplazaAuxiliarContable(chara11);
                          // if chara11[13] = '&' then
                          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_final;
                          // if chara11[13] = '#' then
                          //   chara11 := copy(chara11, 1, 12) + dmvar.final.co_contable;
                          if chara11[13] = '-' then
                            chara11 := copy(chara11, 1, 12);
                          graba_linea(chara11, observa, txt('Otras Part. ' + dmvar.final.co_final, 12), monto, 1, tp_concepto = 0, observa1, observa2, 'N' + ceros(lintstr(nu_neto, 8)), lintstr(tp_concepto, 1) + lintstr(dmvar.titulo.nu_moneda, 1) + ceros(lintstr(tp_concepto + 12, 2)), ' ', loper(nu_oper_bolsa), 0);
                        end;
                      end; //venta
                      EfectivoCli := ca_valor * mt_valor;
                      if dmvar.titulo.sw_f_v_u_o = 'P' then
                        EfectivoCli := ca_valor * mt_valor / 100;
                      if (tp_concepto = 0) and (dmvar.final.tp_cliente = 'P') then
                        EfectivoCli := dmvar2.asignacion.mt_neto;
                    end; //<> P
//							if valora(co_cta_custodia) then
//								GeneraMutuoPasivo('N'+ceros(lintstr(nu_neto,8)));
                    if dmvar2.asignacion.fl_transac <> dmvar2.asignacion.fl_fuera then //reversa contingencia si la fecha es diferente
                      genera_reverso_derecho_cli('N' + ceros(lintstr(nu_neto, 8)));
                    dmvar.final := cliente9;
                    dmvar.adicional := adiciona9;
                    dmvar13.personacnv := personacnv9;
                  end; //existe1
              end; //else BVC
              dmpapel.tbdnetos.Next;
              existe := true;
            end; //while not dmpapel.tbdnetos.eof
          end;
        end;
        dmpapel.tbnetos.Next;
      end;
  end;

var
  genero, existecontab: boolean;
  ini: string;
  num_lote: integer;
  pabo1: pabos;
  fcodAsignacion : string;
begin
  fcodAsignacion := '';
  if Trim(txtasignacion.text) <> '' then
    fcodAsignacion := Trim(Copy(txtasignacion.text,3,20));

  rutalog := DMvar.calendario.tx_dir_ws + 'logcontabolsa_' + FormatDateTime('ddmmyy_hhmmss', now) + '.txt';
  crealog(rutalog);
  escribelog(rutalog, 'Inicio ');
  DMpapel.TBauxcompro.open;
  DMpapel.TBauxdcompro.open;
  DMpapel.TBcompro.close;
  DMpapel.TBdcompro.close;
  DMpapel.TBcompro.open;
  DMpapel.TBdcompro.open;
  CapitalHoy := 0;
  PosicionHoy := 0.1;
  escribelog(rutalog, 'lee_fecha');
  lee_fecha;
  ini := flch_a_jul(TXTdesde.text);
  escribelog(rutalog, 'Elimina Compro Ant');
  with DMpapel.TBpaso do
  begin
    ayer := flch_a_jul(TXTdesde.text);
    ayer := suma_dlia(ayer, -1, true); //ces 18/02/2004
    DMpapel.TBauxcompro.indexname := DMvar.IDcmp[0];
    DMpapel.TBauxcompro.setrange([DMvar.numero_mesa, ''], [DMvar.numero_mesa, ayer]);
    DMpapel.TBauxcompro.last;
    if not DMpapel.TBauxcompro.bof then
    begin
      carga_compro(DMpapel.TBauxcompro);
      ayer := DMvar.compro.fl_comprobante;
    end;

   { DMpapel.TBauxcompro.indexname := DMvar.IDcmp[0];
    DMpapel.TBauxcompro.setrange([DMvar.numero_mesa, flch_a_jul(TXTdesde.text)], [DMvar.numero_mesa, flch_a_jul(TXTdesde.text)]);
    DMpapel.TBauxcompro.first;
    ST1.caption := 'Eliminando ';
    while (not DMpapel.TBauxcompro.eof) do
      with DMvar.compro do
      begin
        carga_compro(DMpapel.TBauxcompro);
        if tx_concepto1 = 'Liquidacion ' + TXTdesde.text then
        begin
          ST1.caption := 'Elim Comprob. Liquid. ';
          DMpapel.TBauxcompro.Edit;
          DMvar.compro.sw_estado := 2;
          graba_compro(dmpapel.tbauxcompro);
          DMpapel.TBauxcompro.post;
          DMpapel.TBauxdcompro.IndexName := DMvar.IDdco[1];
          DMpapel.TBauxdcompro.setrange([nu_mesa, fl_comprobante, nu_comprobante], [nu_mesa, fl_comprobante, nu_comprobante]);
          DMpapel.TBauxdcompro.first;
          while (not DMpapel.TBauxdcompro.eof) do
          begin
            DMpapel.TBauxdcompro.delete;
            DMpapel.TBauxdcompro.first;
          end;
        end;
        DMpapel.TBauxcompro.next;
      end;  }

    frmPapel.eliminaComprobantes(dmvar.numero_mesa,TXTdesde.Text,st1,tpcLiquidacion);

    dmpapel.tbpaso.CancelRange;
    if dmvar2.calendario1.sw_emision then
      dmpapel.tbpaso.indexname := dmvar.idpas[1]
    else
      dmpapel.tbpaso.indexname := dmvar.idpas[2];
    dmpapel.tbpaso.setrange([flch_a_jul(txtdesde.text)], [flch_a_jul(txtdesde.text)]);
    PB1.Position := 0;
    pb1.max := 0;
    genero := false;
    dmpapel.tbpaso.first;
    while (not dmpapel.tbpaso.eof) do
    begin
      st1.Caption := inttostr(pb1.max);
      pb1.max := pb1.max + 1;
      dmpapel.tbpaso.next;
    end;
    pb1.position := 0;
    dmpapel.tbpaso.first;
    st1.caption := ' ';
    lista1 := Tstringlist.create;
    escribelog(rutalog, 'Recorro Pabos');
    with dmvar.pabo do
      while (not dmpapel.tbpaso.eof) do
      begin
        pb1.position := pb1.position + 1;
        carga_paso(dmpapel.tbpaso);
        st1.Caption := 'Revisando Liq. Operac. ' + lintstr(dmvar.pabo.nu_paso, 5);
        dmpapel.tbcorre.FindKey([nu_correspo]);
        carga_correspo(dmpapel.tbcorre);
//				if (dmvar.correspo.nu_sistema = 2) or
//							(dmvar2.calendario1.nu_corredor = 4) then
        if (mt_paso > 0.01) then
          if copy(co_clave, 1, 2) = origen_bolsa then //'02'
//        if (copy(co_clave,3,11) = '00000000000') or (co_clave[3] = '') or (co_clave[3] = ' ') then
          begin
            dmpapel.tbrelacion.indexname := DMvar.idrla[1];
            dmpapel.tbrelacion.setrange([nu_paso], [nu_paso]);
            dmpapel.tbrelacion.first;
            while not dmpapel.tbrelacion.eof do
            begin
              carga_relacion(dmpapel.tbrelacion);
              escribelog(rutalog, 'Encuentro relacion ');
              dmpapel.tbasigna.IndexName := dmvar.idasi[0];
              dmpapel.tbasigna.setrange([dmvar2.relacion.nu_oper_bolsa], [dmvar2.relacion.nu_oper_bolsa]);
              dmpapel.tbasigna.First;

              while not dmpapel.tbasigna.eof do
                with dmvar2.asignacion do
                begin
                  carga_asigna(dmpapel.tbasigna);
                  if (Trim(txtasignacion.Text) = '') or (DMvar2.asignacion.nu_oper_bolsa = fcodAsignacion) then
                  begin
                    escribelog(rutalog, 'Carga_asigna ' + nu_oper_bolsa);
                    st1.caption := 'buscando ' + inttostr(nu_asignacion);
                    busca_titulo(co_valor);
                    DMpapel.TBfinal.IndexName := DMvar.IDfin[2];
                    DMpapel.TBfinal.findkey([dmvar2.asignacion.nu_cliente]);
                    Carga_final(DMpapel.TBfinal);
                    dmpapel.tbadiciona.indexname := dmvar.idadi[0];
                    DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
                    Carga_adiciona(DMpapel.TBadiciona);
                    DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
                    carga_personacnv(DMpapel.TBtpersonacnv);
                    frmpapel.BuscarNumeroPos(dmvar.titulo.sw_f_v_u_o, dmvar.numero_pos); //21/01/2004
                    DMpapel.TBtptcontcnv.findkey([DMvar.titulo.co_tipo, 98, dmvar.numero_pos]); //vehiculo,cartera
                    Carga_tptcontcnv(DMpapel.TBtptcontcnv);
                    if sw_del = 0 then
                      if nu_cliente = dmvar2.relacion.nu_final then
                      begin
                        dmpapel.tbbolsa.indexname := dmvar.idbol[0];
                        dmpapel.tbbolsa.findkey([nu_oper_bolsa, tp_operacion]);
                        carga_bolsa(dmpapel.tbbolsa);
                        escribelog(rutalog, 'Carga_bolsa ');
                        if not genero then
                          graba_cabeza;
                        if (dmvar.final.tp_cliente <> 'P') then
                          liquida_cliente(true);
                        if (fl_transac = fl_fuera) then  //Caso 1026 //ces 01/06/2016
                          if (dmvar.final.tp_cliente <> 'P') then               // Jfiguera no generar asiento contable cuando es cartera propia
                            genera_cmi_cli;                //Caso 1026 //ces 01/06/2016
                        genero := true;
                      end;
                  end;
                  dmpapel.tbasigna.Next;
                end;
              dmpapel.tbrelacion.Next;
            end;
          end;
        dmpapel.tbpaso.Next;
      end;
    if not genero then
    begin
      graba_cabeza;
      genero := true;
    end;
    st1.Caption := ' ';
    escribelog(rutalog, 'Comienza neteo');
    liquida_Neto;
    lista1.free;
    escribelog(rutalog, 'Lleno lista');
    with dmpapel.tbasigna do
    begin
      PB1.Position := 0;
      cancelrange;
      indexname := DMvar.IDasi[2];
      setrange([flch_a_jul(TXTdesde.text)], [flch_a_jul(TXTdesde.text)]);
      first;
      pb1.max := 0;
      lista := Tstringlist.create;
      while (not eof) do
        with dmvar2.asignacion do
        begin
          carga_asigna(dmpapel.tbasigna);
          st1.caption := nu_oper_bolsa;
          if sw_del = 0 then
            if tp_operacion <= 1 then
            begin
              lista.add(fl_fuera + ceros(lintstr(nu_cliente, 6)) + co_cta_custodia + txt(co_valor, 6) + loper(nu_oper_bolsa) + ';' + ceros(lintstr(dmvar2.asignacion.nu_asignacion, 6)));
              pb1.max := pb1.max + 1;
            end;
          st1.Caption := inttostr(pb1.max);
          next;
        end;
      lista.Sorted := true;
//    end;
      st1.caption := '';
      first;
			// genero := false;
      escribelog(rutalog, 'recorro lista');
      while (not eof) do
        with DMvar2.asignacion do
        begin
          carga_asigna(DMpapel.TBasigna);
          if (Trim(txtasignacion.Text) = '') or (DMvar2.asignacion.nu_oper_bolsa = fcodAsignacion) then
          begin
            escribelog(rutalog, 'carga_asigna ' + nu_oper_bolsa);
            PB1.position := PB1.position + 1;
            ST1.caption := lintstr(nu_asignacion, 6) + '  ' + loper(nu_oper_bolsa);
            if (tp_operacion <= 1) then
              if (sw_del = 0) then
              if (tp_concepto = 0) or (tp_concepto = 1) then
              begin
                if not genero then
                  graba_cabeza;
                genero := true;
                DMpapel.TBtitulo.indexname := DMvar.IDtit[1];
                DMpapel.TBtitulo.findkey([DMvar2.asignacion.co_valor]);
                Carga_titulo(DMpapel.TBtitulo);
                DMpapel.TBtipot.findkey([DMvar.titulo.co_tipo]);
                Carga_tipotit(DMpapel.TBtipot);
                DM00a.Busca_precio(dmvar2.asignacion.co_valor, flch_a_jul(TXTdesde.text));
                DMpapel.TBfinal.IndexName := DMvar.IDfin[2];
                DMpapel.TBfinal.findkey([dmvar2.asignacion.nu_cliente]);
                Carga_final(DMpapel.TBfinal);
                dmpapel.tbadiciona.indexname := dmvar.IDadi[0];
                DMpapel.TBadiciona.findkey([DMvar.final.nu_final]);
                Carga_adiciona(DMpapel.TBadiciona);
                DMpapel.TBtpersonacnv.findkey([DMvar.adicional.tp_persona]);
                carga_personacnv(DMpapel.TBtpersonacnv);
                frmpapel.BuscarNumeroPos(dmvar.titulo.sw_f_v_u_o, dmvar.numero_pos); //21/01/2004
                DMpapel.TBtptcontcnv.findkey([DMvar.titulo.co_tipo, 98, dmvar.numero_pos]); //vehiculo,cartera
                Carga_tptcontcnv(DMpapel.TBtptcontcnv);
                dmpapel.tbbolsa.indexname := dmvar.IDbol[0];
                dmpapel.tbbolsa.findkey([nu_oper_bolsa, tp_operacion]);
                carga_bolsa(dmpapel.tbbolsa);
                escribelog(rutalog, 'carga_bolsa ' + nu_oper_bolsa);
                if fl_fuera = flch_a_jul(TXTdesde.text) then
                  if dmvar.final.tp_cliente = 'P' then
                    liquida_cartera;
              end;
          end;
          next;
        end;
      lista.free;
    end;
		//pasa otros
    pb1.position := 0;
    dmpapel.tbcontab.open;
    carga_indices(dmpapel.tbcontab, dmvar.idcon);
    dmpapel.tbpaso.CancelRange;
    if dmvar2.calendario1.sw_emision then
      dmpapel.tbpaso.indexname := dmvar.idpas[1]
    else
      dmpapel.tbpaso.indexname := dmvar.idpas[2];
    dmpapel.tbpaso.setrange([flch_a_jul(txtdesde.text)], [flch_a_jul(txtdesde.text)]);
    dmpapel.tbpaso.first;
    st1.caption := ' ';
    lista := Tstringlist.create;
    with dmvar.pabo do
      while (not dmpapel.tbpaso.eof) do
      begin
        pb1.position := pb1.position + 1;
        carga_paso(dmpapel.tbpaso);
        dmpapel.tbcorre.FindKey([nu_correspo]);
        carga_correspo(dmpapel.tbcorre);
        st1.Caption := 'Revisando Otros ' + lintstr(dmvar.pabo.nu_paso, 5);
        existecontab := false;
        if (mt_paso > 0.01) then
          if dmvar.correspo.nu_sistema = 2 then //bolsa
          begin
            if (nu_lote = 0) or (trim(co_clave) = '') then
            begin
              DMPAPEL.tbcontab.IndexName := DMvar.IDcon[1];
              dmpapel.tbcontab.setrange([nu_paso], [nu_paso]);
              while not dmpapel.tbcontab.eof do
              begin
                carga_contab(dmpapel.tbcontab);
                if dmvar.contab.mt_contab > 0 then
                begin
                  if not genero then
                    graba_cabeza;
                  graba_linea(dmvar.contab.co_cuenta, tx_concepto,
//											 txt('Liq. Otras'+dmvar.correspo.nm_correspo,12),abs(dmvar.contab.mt_contab),1,dmvar.contab.sw_deb_cre,  //cambio de referencia ces 04/10/2004
                    txt(dmvar.pabo.nu_deposito, 12), abs(dmvar.contab.mt_contab), 1, dmvar.contab.sw_deb_cre,  //cambio de referencia ces 04/10/2004
                    ' Ref.' + dmvar.contab.nu_refer, txt(' ', 13) + ceros(lintstr(dmvar.pabo.tp_pago, 2)), ' ', '0' + lintstr(dmvar.correspo.nu_moneda, 1) + chara, dmvar.pabo.nu_deposito, ' ', dmvar.pabo.nu_correspo);
                  existecontab := true;
                  genero := true;
                end;
                dmpapel.tbcontab.Next;
              end;
              if existecontab then
                graba_linea(dmvar.correspo.co_contable, 'Otros Mov. Bancar. ' + txtdesde.text,
//										 txt('Liq. Otras'+dmvar.correspo.nm_correspo,12),abs(dmvar.pabo.mt_paso),1,dmvar.pabo.tp_paso = 'E',' ', //cambio de referencia ces 04/10/2004
                  txt(dmvar.pabo.nu_deposito, 12), abs(dmvar.pabo.mt_paso), 1, dmvar.pabo.tp_paso = 'E', ' ', //cambio de referencia ces 04/10/2004
                  txt(' ', 13) + ceros(lintstr(dmvar.pabo.tp_pago, 2)), ' ', '0' + lintstr(dmvar.correspo.nu_moneda, 1) + chara, dmvar.pabo.nu_deposito, ' ', dmvar.pabo.nu_correspo);
            end
            else if (nu_lote <> 0) and (copy(co_clave, 1, 8) = origen_bolsa + 'CTAINV') then
            begin
              num_lote := DMvar.pabo.nu_lote;
              with DMaux.TBpaso do
              begin
                indexname := DMvar.IDpas[1];
                setrange([DMvar.pabo.fl_emision], [DMvar.pabo.fl_emision]);
                pabo1 := DMvar.pabo;
                first;
                while (not DMaux.TBpaso.eof) do
                  with DMvar.pabo do
                  begin
                    carga_paso(DMaux.TBpaso);
                    if mt_paso > 0 then
                      if nu_lote = num_lote then
                        if not RevisaPaso(ceros(lintstr(nu_paso, 10))) then
                        begin
                          if not genero then
                            graba_cabeza;
                          genero := true;
                          lista.Add(ceros(lintstr(nu_paso, 10)));
                          dmpapel.tbcorre.FindKey([nu_correspo]);
                          carga_correspo(dmpapel.tbcorre);
                          graba_linea(dmvar.correspo.co_contable, tx_concepto,
//											 txt('Liq. Trans'+dmvar.correspo.nm_correspo,12),abs(dmvar.pabo.mt_paso),1,dmvar.pabo.tp_paso = 'E', //cambio de referencia ces 04/10/2004
                            txt(dmvar.pabo.nu_deposito, 12), abs(dmvar.pabo.mt_paso), 1, dmvar.pabo.tp_paso = 'E', //cambio de referencia ces 04/10/2004
                            'Transf.Cta.Inv ', txt(tx_concepto, 13) + ceros(lintstr(dmvar.pabo.tp_pago, 2)), 'A' + copy(tx_concepto, 3, 11), '0' + lintstr(dmvar.correspo.nu_moneda, 1), dmvar.pabo.nu_deposito, ' ', dmvar.pabo.nu_correspo);
                        end;
                    next;
                  end;
                cancelrange;
                DMvar.pabo := pabo1;
              end;
            end;
          end;
        dmpapel.tbpaso.Next;
      end;
    dmpapel.tbcontab.close;
//   end;
    ST1.caption := 'Fin de Proceso ';
    PB1.Position := 0;
    lista.free;
  end;
  DMpapel.TBauxcompro.close;
  DMpapel.TBauxdcompro.close;

  if swLog then
  begin
    logAsientosLiquida.generaArchivo;
    freeandnil(logAsientosLiquida);
  end;
end;

procedure Tfrmliquidacion.FormShow(Sender: TObject);
begin
  swLog :=false;  // Jfiguera 25-04-2023 para futura auditoria y optimizacion de codigo, mantener en produccion en false


  DMaux.tbasigna.open;
  DMaux.tbbolsa.open;
  DMaux.tbpaso.open;
  dmvar.numero_mesa := 1; //21/01/2004
  exit; // 21/01/2004
  
  dmvar.numero_pos := 98;
  dmpapel.tbcarteras.first;
  while (not dmpapel.tbcarteras.eof) and (dmvar.numero_pos = 98) do
    with dmpapel.tbcarteras do
    begin
      if (pos('omercializaci', fieldbyname('tx_cartera').asstring) > 0) then
        dmvar.numero_pos := fieldbyname('nu_cartera').asinteger;
      next;
    end;
end;

procedure Tfrmliquidacion.Button2Click(Sender: TObject);
begin
  close;
end;

procedure Tfrmliquidacion.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DMaux.tbpaso.close;
  DMaux.tbasigna.close;
  DMaux.tbbolsa.close;
end;

procedure Tfrmliquidacion.crealog(rutarchivo: string);
var
  archilog: textfile;
begin
  assignfile(archilog, rutarchivo);
  rewrite(archilog);
  closefile(archilog);
end;

function Tfrmliquidacion.reemplazaAuxiliarContable(cuenta : string):string;
var fresultado : string;
begin
  fresultado := cuenta;
  if fresultado[13] = '&' then
    fresultado := copy(fresultado, 1, 12) + dmvar.final.co_final; 
  if fresultado[13] = '#' then
    fresultado := copy(fresultado, 1, 12) + dmvar.final.co_contable;  
  result := fresultado;
end;                           


end.

