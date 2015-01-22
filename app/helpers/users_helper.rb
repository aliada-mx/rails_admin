module UsersHelper
  def generate_random_pronouncable_password(size: 4)
    vowels = %w{a e i o u}
    consonants = %w(b c d f g h j l m n p qu r s t v w x z ch do ta te ka de ti to ra ke de es no te el la do ma na te en)

    switch, password = true, ''
    (size * 2).times do
       password << (switch ? consonants [rand * consonants.size] : vowels[rand * vowels.size]) 
       switch = !switch 
    end
    password
  end
end
