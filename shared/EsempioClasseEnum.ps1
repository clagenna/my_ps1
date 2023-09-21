#definisco un enumerato
enum Frutti {
  Mela = 1
  Pera = 2
  banana = 3
}

# Definisci una classe
class TipoNomeClasse
{
   # 
   [Frutti]$frutta

   # Proprietà con convalida impostata
   [ValidateSet("val1", "Val2")][string] $conConv

   # Proprietà statica
   static [hashtable] $s_val

   # La proprietà Hidden non viene visualizzata come risultato di Get-Member
   hidden [int] $m_hidd

   # Costruttore
   TipoNomeClasse ([string] $s)
   {
       $this.conConv = $s       
   }
   # Costruttore 2
   TipoNomeClasse ([string] $s, [int] $q)
   {
       $this.conConv = $s       
       $this.m_hidd = $q
   }

   # Metodo statico
   static [void] MemberMethod1([hashtable] $h)
   {
       [TipoNomeClasse]::s_val = $h
   }

   # Metodo dell'istanza
   [int] MemberMethod2([int] $i)
   {
       $this.m_hidd = $i
       return $this.m_hidd
   }
}

$p = New-Object TipoNomeClasse  "val2"
$p.frutta = [frutti]::banana
$p
$pq = New-Object TipoNomeClasse  "val2", 1234
$pq.frutta = 2
$pq



