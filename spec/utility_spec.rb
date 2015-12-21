# encoding: utf-8
require_relative "./spec_helper"

describe "Utility functions to handle names of people" do
  before(:all) do
    @utility = Collector::AgentUtility
  end

  it "should capitalize mistaken lowercase first initials" do
    input = "r.C. Smith"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:particle, :given, :family)).to eq(["r.C.", nil, "Smith"])
    expect(@utility.clean(parsed[0]).to_h).to eq({given:"R.C.", family:"Smith"})
  end

  it "should clean family names with extraneous period" do
    input = "C. Tanner."
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['C.', 'Tanner.'])
    expect(@utility.clean(parsed[0]).to_h).to eq({given:'C.', family: 'Tanner'})
  end

  it "should remove numerical values and lowercase letter" do
    input = "23440a Ian D. Macdonald"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(["Ian D.", "Macdonald"])
  end

  it "should remove numerical values and capital letter" do
    input = "23440G Ian D. Macdonald"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(["Ian D.", "Macdonald"])
  end

  it "should remove numerical values and lowercase letter in brackets" do
    input = "23440(a) Ian D. Macdonald"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(["Ian D.", "Macdonald"])
  end

  it "should remove 'et al'" do
    input = "Jack Smith et al"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove 'et al.'" do
    input = "Jack Smith et al."
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove 'and others'" do
    input = "Jack Smith and others"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove '& others'" do
    input = "Jack Smith & others"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove 'etc'" do
    input = "Jack Smith etc"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove 'etc.'" do
    input = "Jack Smith etc."
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove ', YYYY' " do
    input = "Jack Smith, 2009"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove brackets from name" do
    input = "W.P. Coreneuk(?)"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['W.P.', 'Coreneuk'])
  end

  it "should explode by 'stet!'" do
    input = "Jack Smith stet!"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should explode by 'stet'" do
    input = "Jack Smith stet 1989"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should explode by 'stet,'" do
    input = "Jack Smith stet, 1989"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
  end

  it "should remove 'UNKNOWN'" do
    input = "UNKNOWN"
    parsed = @utility.parse(input)
    expect(parsed).to eq([])
  end

  it "should not parse what does not resemble a name" do
    input = "EB"
    parsed = @utility.parse(input)
    expect(parsed).to eq([])
  end

  it "should remove extraneous material" do
    input = "Unknown [J. S. Erskine?]"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['J. S.', 'Erskine'])
  end

  it "should preserve caps in family names" do
    input = "Chris MacQuarrie"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Chris', 'MacQuarrie'])
    expect(@utility.clean(parsed[0]).to_h).to eq({ family: "MacQuarrie", given: "Chris"})
  end

  it "should remove more exteneous material" do
    input = "Jack [John]: Smith12345"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack John', 'Smith'])
  end

  it "should explode names with ' - '" do
    input = "Jack Smith - Yves St-Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'St-Archambault'])
  end

  it "should explode names with ' – '" do
    input = "Jack Smith   –   Yves St-Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'St-Archambault'])
  end

  it "should explode names with 'and'" do
    input = "Jack Smith and Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'or'" do
    input = "Jack Smithor or Orlando Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smithor'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Orlando', 'Archambault'])
  end

  it "should explode names with 'AND'" do
    input = "Jack Smith AND Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode multiple names with 'and'" do
    input = "Jack Smith and Yves Archambault and Don Johnson"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(3)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
    expect(parsed[2].values_at(:given, :family)).to eq(['Don', 'Johnson'])
  end

  it "should explode names with ';'" do
    input = "Jack Smith; Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with '|'" do
    input = "Jack Smith | Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with '&'" do
    input = "Jack Smith & Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode lists of names that contain ',' and '&'" do
    input = "V. Crecco, J. Savage & T.A. Wheeler"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(3)
    expect(parsed[0].values_at(:given, :family)).to eq(['V.', 'Crecco'])
    expect(parsed[1].values_at(:given, :family)).to eq(['J.', 'Savage'])
    expect(parsed[2].values_at(:given, :family)).to eq(['T.A.', 'Wheeler'])
  end

  it "should explode lists of names with initials (reversed), commas, and '&'" do
    input = "Harkness, W.J.K., Dickinson, J.C., & Marshall, N."
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(3)
    expect(parsed[0].values_at(:given, :family)).to eq(['W.J.K.', 'Harkness'])
    expect(parsed[1].values_at(:given, :family)).to eq(['J.C.', 'Dickinson'])
    expect(parsed[2].values_at(:given, :family)).to eq(['N.', 'Marshall'])
  end

  it "should explode lists of names with semicolons and commas in reverse order" do
    input = "Gad., L.; Dawson, J.; Wyatt, N.; Gerring, J."
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(4)
    expect(parsed[0].values_at(:given, :family)).to eq(['L.', 'Gad.'])
    expect(parsed[1].values_at(:given, :family)).to eq(['J.', 'Dawson'])
    expect(parsed[2].values_at(:given, :family)).to eq(['N.', 'Wyatt'])
    expect(parsed[3].values_at(:given, :family)).to eq(['J.', 'Gerring'])
  end

  it "should explode lists of names with initials (forward), commas and '&'" do
    input = "N. Lujan, D. Werneke, D. Taphorn, D. German & D. Osorio"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(5)
    expect(parsed[0].values_at(:given, :family)).to eq(['N.', 'Lujan'])
    expect(parsed[1].values_at(:given, :family)).to eq(['D.', 'Werneke'])
    expect(parsed[2].values_at(:given, :family)).to eq(['D.', 'Taphorn'])
    expect(parsed[3].values_at(:given, :family)).to eq(['D.', 'German'])
    expect(parsed[4].values_at(:given, :family)).to eq(['D.', 'Osorio'])
  end

  it "should explode names with '/'" do
    input = "Jack Smith / Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'et'" do
    input = "Jack Smith et Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'with'" do
    input = "Jack Smith with Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'with' and 'and'" do
    input = "Jack Smith with Yves Archambault and Don Johnson"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(3)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
    expect(parsed[2].values_at(:given, :family)).to eq(['Don', 'Johnson'])
  end

  it "should explode names with 'by'" do
    input = "by P. Zika"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['P.', 'Zika'])
  end

  it "should explode names with 'annotated'" do
    input = "annotated Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'annotated by'" do
    input = "annotated by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'conf'" do
    input = "Jack Johnson conf Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'conf'" do
    input = "Jack Johnson conf Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'conf.'" do
    input = "Jack Johnson conf. Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'conf by'" do
    input = "Jack Johnson conf by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'conf. by'" do
    input = "Jack Johnson conf. by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'confirmed by'" do
    input = "Jack Johnson confirmed by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'checked:'" do
    input = "C.E. Garton 1980 checked:W.G. Argus 1980"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['C.E.', 'Garton'])
    expect(parsed[1].values_at(:given, :family)).to eq(['W.G.', 'Argus'])
  end

  it "should explode names with 'checked by'" do
    input = "Jack Johnson checked by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'Checked By'" do
    input = "Checked By Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'dupl'" do
    input = "Jack Johnson dupl Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'dupl.'" do
    input = "Jack Johnson dupl. Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'dup by'" do
    input = "Jack Johnson dup by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'dup. by'" do
    input = "Jack Johnson dup. by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'ex. by'" do
    input = "Rex Johnson ex. by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'ex by'" do
    input = "Rex Byron ex by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'examined by'" do
    input = "Rex Byron examined by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'in part'" do
    input = "Rex Byron in part Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'in part by'" do
    input = "Rex Byron in part by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'redet by'" do
    input = "Jack Smith redet. by Michael Jackson"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'Smith'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Michael', 'Jackson'])
  end

  it "should explode names with 'stet'" do
    input = "Anna Roberts stet R. Scagel 1981"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Anna', 'Roberts'])
    expect(parsed[1].values_at(:given, :family)).to eq(['R.', 'Scagel'])
  end

  it "should explode names with 'ver by'" do
    input = "Rex Byron ver by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'ver. by'" do
    input = "Rex Byron ver. by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with 'verified by'" do
    input = "Rex Byron verified by Yves Archambault"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Rex', 'Byron'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Yves', 'Archambault'])
  end

  it "should explode names with abbreviation for verified by" do
    input = "W.W. Diehl; Verif.: C.L. Shear"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['W.W.', 'Diehl'])
    expect(parsed[1].values_at(:given, :family)).to eq(['C.L.', 'Shear'])
  end

  it "should explode names with verified indicator in French" do
    input = "Vérifié Michelle Garneau"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Michelle', 'Garneau'])
  end

  it "should explode names with complex verif. statements with year" do
    input = "Gji; Verif. S. Churchill; 1980"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Gji', nil])
    expect(parsed[1].values_at(:given, :family)).to eq(['S.', 'Churchill'])
  end

  it "should deal with 'Ver By'" do
    input = "S. Ross Ver By P. Perrin"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['S.', 'Ross'])
    expect(parsed[1].values_at(:given, :family)).to eq(['P.', 'Perrin'])
  end

  it "should explode a complicated example" do
    input = "Vernon C. Brink; Thomas C. Brayshaw stet! 1979"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Vernon C.', 'Brink'])
    expect(parsed[1].values_at(:given, :family)).to eq(['Thomas C.', 'Brayshaw'])
  end

  it "should explode names with extraneous commas" do
    input = "4073 A.A. Beetle, with D.E. Beetle and Alva Hansen"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(3)
    expect(parsed[0].values_at(:given, :family)).to eq(['A.A.', 'Beetle'])
    expect(parsed[1].values_at(:given, :family)).to eq(['D.E.', 'Beetle'])
    expect(parsed[2].values_at(:given, :family)).to eq(['Alva', 'Hansen'])
  end

  it "should explode names with extraneous period" do
    input = "C. Tanner.; M.W. Hawkes"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['C.', 'Tanner.'])
    expect(parsed[1].values_at(:given, :family)).to eq(['M.W.', 'Hawkes'])
  end

  it "should explode names with Jan. 14, 2013 included in string" do
    input = "Jan Jones Jan. 14, 2013"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jan', 'Jones'])
  end

  it "should explode names with freeform dates in the string" do
    input = "Richard Robohm on 15 January 2013"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Richard', 'Robohm'])
  end

  it "should explode names with structured dates in the string" do
    input = "C.J. Bird 20/Aug./1980"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['C.J.', 'Bird'])
  end

  it "should explode names with dates separated by commas in the string" do
    input = "K. January; January, 1979"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['K.', 'January'])
  end
  
  it "should explode names with possibly conflicting months in the string" do
    input = "Michael May May 2013"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Michael', 'May'])
  end

  it "should explode names with months (in French) in the string" do
    input = "Jacques, Avril décembre 2013"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Avril', 'Jacques'])
  end

  it "should explode names with possibly conflicting months (in French) in the string" do
    input = "Jacques, Avril avril 2013"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Avril', 'Jacques'])
  end

  it "should explode names with a year and month (normal case) at the end of a string" do
    input = "Paul Kroeger 2006 May"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Paul', 'Kroeger'])
  end

  it "should explode names with a year and month (lower case) at the end of a string" do
    input = "Paul Kroeger 2006 may"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Paul', 'Kroeger'])
  end

  it "should explode a messy list" do
    input = "Winterbottom, R.;Katz, L.;& CI team"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(3)
    expect(parsed[0].values_at(:given, :family)).to eq(['R.', 'Winterbottom'])
    expect(parsed[1].values_at(:given, :family)).to eq(['L.', 'Katz'])
    expect(parsed[2].values_at(:given, :family)).to eq(['CI', 'team'])
  end

  it "should reject an empty name" do
    input = "Norman Johnson and P"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(2)
    expect(parsed[0].values_at(:given, :family)).to eq(['Norman', 'Johnson'])
    expect(parsed[1].values_at(:given, :family)).to eq(["P", nil])
  end

  it "should parse name with given initials without period(s)" do
    input = "JH Picard"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['JH', 'Picard'])
    expect(@utility.clean(parsed[0]).to_h).to eq({ family: "Picard", given: "J.H."})
  end

  it "should capitalize surnames like 'Jack smith'" do
    input = "Jack smith"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Jack', 'smith'])
    expect(@utility.clean(parsed[0]).to_h).to eq({ family: "Smith", given: "Jack"})
  end

  it "should capitalize names like 'C. YOUNG'" do
    input = "C. YOUNG"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['C.', 'YOUNG'])
    expect(@utility.clean(parsed[0]).to_h).to eq({ family: "Young", given: "C."})
  end

  it "should properly handle and capitalize utf-8 characters" do
    input = "Sicard, Léas"
    parsed = @utility.parse(input)
    expect(parsed.size).to eq(1)
    expect(parsed[0].values_at(:given, :family)).to eq(['Léas', 'Sicard'])
    expect(@utility.clean(parsed[0]).to_h).to eq({ family: "Sicard", given: "Léas"})
  end

  it "should clean a doi with http://dx.doi.org" do
    input = "http://dx.doi.org/10.12345/12345"
    cleaned = @utility.doi_clean(input)
    expect(cleaned).to eq("10.12345/12345")
  end

  it "should clean a doi with http://doi.org" do
    input = "http://doi.org/10.12345/12345"
    cleaned = @utility.doi_clean(input)
    expect(cleaned).to eq("10.12345/12345")
  end

  it "should clean a doi with doi:" do
    input = "doi:10.12345/12345"
    cleaned = @utility.doi_clean(input)
    expect(cleaned).to eq("10.12345/12345")
  end

  it "should clean a doi with DOI:" do
    input = "DOI:10.12345/12345"
    cleaned = @utility.doi_clean(input)
    expect(cleaned).to eq("10.12345/12345")
  end

  it "should clean a doi with DOI= " do
    input = "DOI= 10.12345/12345"
    cleaned = @utility.doi_clean(input)
    expect(cleaned).to eq("10.12345/12345")
  end

end
